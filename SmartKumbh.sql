BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables
        WHERE table_name IN (
            'ACTIVITY_LOG','LOST_AND_FOUND','PILGRIM_PURCHASES',
            'PILGRIM_TREATMENTS','INCIDENT_REPORTS','PILGRIM_TRANSPORTATION',
            'PILGRIM_ACCOMMODATION','PILGRIMS','VENDORS','ACCOMMODATION',
            'GHATS','FIRE_STATIONS','POLICE_OFFICERS','POLICE_STATIONS',
            'DOCTORS','HOSPITALS','TRANSPORTATION','EMERGENCY_CONTACT'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

BEGIN
    FOR s IN (
        SELECT sequence_name FROM user_sequences
        WHERE sequence_name = 'SEQ_ACTIVITY_LOG'
    ) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- ============================================================
-- SECTION 1: CREATE TABLES
-- ============================================================

-- Oracle Notes:
--   BOOLEAN  → NUMBER(1) CHECK (col IN (0,1))  (1=TRUE, 0=FALSE)
--   ENUM     → VARCHAR2 + CHECK constraint
--   AUTO_INCREMENT → SEQUENCE + trigger (or GENERATED ALWAYS AS IDENTITY in Oracle 12c+)
--   VARCHAR  → VARCHAR2
--   DATETIME → TIMESTAMP
--   NOW()    → SYSTIMESTAMP

CREATE TABLE Hospitals (
    Hospital_ID         NUMBER          PRIMARY KEY,
    Hospital_Name       VARCHAR2(100)   NOT NULL,
    Location            VARCHAR2(100),
    Capacity            NUMBER          CHECK (Capacity > 0),
    Contact_Number      VARCHAR2(15),
    Email               VARCHAR2(100),
    ICU_Beds            NUMBER          DEFAULT 0,
    Emergency_Available NUMBER(1)       DEFAULT 1 CHECK (Emergency_Available IN (0,1)),
    Established_Year    NUMBER
);

CREATE TABLE Doctors (
    Doctor_ID           NUMBER          PRIMARY KEY,
    Name                VARCHAR2(100)   NOT NULL,
    Specialization      VARCHAR2(100),
    Hospital_ID         NUMBER          NOT NULL,
    Contact_Number      VARCHAR2(15),
    Email               VARCHAR2(100),
    Experience_Years    NUMBER          DEFAULT 0,
    Availability_Status VARCHAR2(20)    DEFAULT 'Available'
                            CHECK (Availability_Status IN ('Available','On Leave','Off Duty')),
    Shift               VARCHAR2(20)    DEFAULT 'Morning'
                            CHECK (Shift IN ('Morning','Afternoon','Night')),
    CONSTRAINT fk_doc_hospital FOREIGN KEY (Hospital_ID) REFERENCES Hospitals(Hospital_ID)
);

CREATE TABLE Police_Stations (
    Station_ID     NUMBER          PRIMARY KEY,
    Station_Name   VARCHAR2(100)   NOT NULL,
    Location       VARCHAR2(100),
    Contact_Number VARCHAR2(15),
    In_Charge      VARCHAR2(100),
    Zone           VARCHAR2(50)
);

CREATE TABLE Police_Officers (
    Officer_ID     NUMBER          PRIMARY KEY,
    Name           VARCHAR2(100)   NOT NULL,
    Officer_Rank   VARCHAR2(50),
    Station_ID     NUMBER          NOT NULL,
    Contact_Number VARCHAR2(15),
    Badge_Number   VARCHAR2(20)    UNIQUE,
    Duty_Zone      VARCHAR2(50),
    On_Duty        NUMBER(1)       DEFAULT 1 CHECK (On_Duty IN (0,1)),
    CONSTRAINT fk_off_station FOREIGN KEY (Station_ID) REFERENCES Police_Stations(Station_ID)
);

CREATE TABLE Fire_Stations (
    Fire_Station_ID NUMBER          PRIMARY KEY,
    Station_Name    VARCHAR2(100),
    Location        VARCHAR2(100)   NOT NULL,
    Contact_Number  VARCHAR2(15),
    In_Charge       VARCHAR2(100),
    Total_Units     NUMBER          DEFAULT 0,
    Available_Units NUMBER          DEFAULT 0
);

CREATE TABLE Ghats (
    Ghat_ID             NUMBER          PRIMARY KEY,
    Ghat_Name           VARCHAR2(100)   NOT NULL,
    Location            VARCHAR2(100),
    Capacity            NUMBER,
    Status              VARCHAR2(20)    DEFAULT 'Open'
                            CHECK (Status IN ('Open','Closed','Restricted')),
    Current_Crowd_Count NUMBER          DEFAULT 0,
    Assigned_Officer_ID NUMBER,
    CONSTRAINT fk_ghat_officer FOREIGN KEY (Assigned_Officer_ID) REFERENCES Police_Officers(Officer_ID)
);

CREATE TABLE Accommodation (
    Tent_ID        NUMBER          PRIMARY KEY,
    Tent_Name      VARCHAR2(100),
    Location       VARCHAR2(100),
    Total_Beds     NUMBER          DEFAULT 0,
    Available_Beds NUMBER          DEFAULT 0,
    Tent_Type      VARCHAR2(20)    DEFAULT 'Standard'
                        CHECK (Tent_Type IN ('Deluxe','Standard','Basic')),
    Price_Per_Day  NUMBER(8,2)     DEFAULT 0.00,
    Amenities      VARCHAR2(200),
    Contact_Person VARCHAR2(100)
);

CREATE TABLE Vendors (
    Vendor_ID       NUMBER          PRIMARY KEY,
    Vendor_Name     VARCHAR2(100)   NOT NULL,
    Stall_Type      VARCHAR2(100),
    Location        VARCHAR2(100),
    Contact         VARCHAR2(15),
    License_Number  VARCHAR2(50)    UNIQUE,
    Operating_Hours VARCHAR2(50)    DEFAULT '06:00-22:00',
    Status          VARCHAR2(20)    DEFAULT 'Active'
                        CHECK (Status IN ('Active','Inactive','Suspended'))
);

CREATE TABLE Transportation (
    Transport_ID   NUMBER          PRIMARY KEY,
    Vehicle_Type   VARCHAR2(50),
    Route          VARCHAR2(100),
    Capacity       NUMBER,
    Departure      VARCHAR2(50),
    Driver_Name    VARCHAR2(100),
    Vehicle_Number VARCHAR2(20),
    Status         VARCHAR2(20)    DEFAULT 'Available'
                        CHECK (Status IN ('Available','In-Route','Maintenance')),
    Arrival_Time   VARCHAR2(50)
);

CREATE TABLE Emergency_Contact (
    Contact_ID     NUMBER          PRIMARY KEY,
    Contact_Name   VARCHAR2(100)   NOT NULL,
    Contact_Number VARCHAR2(15)    NOT NULL,
    Department     VARCHAR2(100),
    Station_ID     NUMBER,
    Availability   VARCHAR2(20)    DEFAULT '24x7',
    Email          VARCHAR2(100),
    CONSTRAINT fk_ec_station FOREIGN KEY (Station_ID) REFERENCES Police_Stations(Station_ID)
);

CREATE TABLE Pilgrims (
    Pilgrim_ID        NUMBER          PRIMARY KEY,
    Name              VARCHAR2(100)   NOT NULL,
    Age               NUMBER          CHECK (Age > 0),
    Gender            CHAR(1)         CHECK (Gender IN ('M','F','O')),
    Contact_Number    VARCHAR2(15)    UNIQUE NOT NULL,
    City              VARCHAR2(100),
    Blood_Group       VARCHAR2(5),
    Aadhaar_Number    VARCHAR2(12)    UNIQUE,
    Nationality       VARCHAR2(50)    DEFAULT 'Indian',
    Email             VARCHAR2(100),
    State             VARCHAR2(50),
    Registration_Date TIMESTAMP       DEFAULT SYSTIMESTAMP,
    Status            VARCHAR2(20)    DEFAULT 'Active'
                            CHECK (Status IN ('Active','Departed','Missing'))
);

CREATE TABLE Pilgrim_Accommodation (
    Booking_ID     NUMBER  PRIMARY KEY,
    Pilgrim_ID     NUMBER  NOT NULL,
    Tent_ID        NUMBER  NOT NULL,
    Check_In_Date  DATE,
    Check_Out_Date DATE,
    CONSTRAINT fk_pa_pilgrim FOREIGN KEY (Pilgrim_ID) REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_pa_tent    FOREIGN KEY (Tent_ID)    REFERENCES Accommodation(Tent_ID)
);

CREATE TABLE Pilgrim_Transportation (
    PT_ID        NUMBER  PRIMARY KEY,
    Pilgrim_ID   NUMBER  NOT NULL,
    Transport_ID NUMBER  NOT NULL,
    Travel_Date  DATE,
    CONSTRAINT fk_pt_pilgrim    FOREIGN KEY (Pilgrim_ID)   REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_pt_transport  FOREIGN KEY (Transport_ID) REFERENCES Transportation(Transport_ID)
);

CREATE TABLE Incident_Reports (
    Incident_ID       NUMBER          PRIMARY KEY,
    Description       VARCHAR2(200),
    Priority          VARCHAR2(10)    CHECK (Priority IN ('High','Medium','Low')),
    Report_Date       DATE,
    Pilgrim_ID        NUMBER,
    Station_ID        NUMBER,
    Status            VARCHAR2(30)    DEFAULT 'Open'
                            CHECK (Status IN ('Open','Under Investigation','Resolved')),
    Resolution_Date   DATE,
    Resolved_By       VARCHAR2(100),
    Incident_Location VARCHAR2(100),
    CONSTRAINT fk_ir_pilgrim FOREIGN KEY (Pilgrim_ID) REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_ir_station FOREIGN KEY (Station_ID) REFERENCES Police_Stations(Station_ID)
);

CREATE TABLE Pilgrim_Treatments (
    Treatment_ID   NUMBER          PRIMARY KEY,
    Pilgrim_ID     NUMBER          NOT NULL,
    Doctor_ID      NUMBER          NOT NULL,
    Diagnosis      VARCHAR2(200),
    Treat_Date     DATE,
    Prescription   VARCHAR2(300),
    Follow_Up_Date DATE,
    Hospital_ID    NUMBER,
    CONSTRAINT fk_pt2_pilgrim  FOREIGN KEY (Pilgrim_ID)  REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_pt2_doctor   FOREIGN KEY (Doctor_ID)   REFERENCES Doctors(Doctor_ID),
    CONSTRAINT fk_pt2_hospital FOREIGN KEY (Hospital_ID) REFERENCES Hospitals(Hospital_ID)
);

CREATE TABLE Pilgrim_Purchases (
    Purchase_ID   NUMBER          PRIMARY KEY,
    Pilgrim_ID    NUMBER          NOT NULL,
    Vendor_ID     NUMBER          NOT NULL,
    Item_Name     VARCHAR2(100),
    Amount        NUMBER(10,2)    CHECK (Amount >= 0),
    Purchase_Date DATE,
    CONSTRAINT fk_pp_pilgrim FOREIGN KEY (Pilgrim_ID) REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_pp_vendor  FOREIGN KEY (Vendor_ID)  REFERENCES Vendors(Vendor_ID)
);

CREATE TABLE Lost_And_Found (
    Item_ID               NUMBER          PRIMARY KEY,
    Item_Name             VARCHAR2(100),
    Status                VARCHAR2(20)    CHECK (Status IN ('Lost','Found','Claimed')),
    Report_Date           DATE,
    Pilgrim_ID            NUMBER,
    Item_Description      VARCHAR2(200),
    Found_Location        VARCHAR2(100),
    Claimed_By_Pilgrim_ID NUMBER,
    CONSTRAINT fk_lf_pilgrim        FOREIGN KEY (Pilgrim_ID)            REFERENCES Pilgrims(Pilgrim_ID),
    CONSTRAINT fk_lf_claimed_pilgrim FOREIGN KEY (Claimed_By_Pilgrim_ID) REFERENCES Pilgrims(Pilgrim_ID)
);

-- Audit log — uses SEQUENCE + trigger instead of AUTO_INCREMENT
CREATE SEQUENCE seq_activity_log START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE Activity_Log (
    Log_ID      NUMBER          PRIMARY KEY,
    Action_Type VARCHAR2(50),
    Description VARCHAR2(200),
    Log_Time    TIMESTAMP       DEFAULT SYSTIMESTAMP
);

-- Trigger to auto-populate Log_ID from sequence
CREATE OR REPLACE TRIGGER trg_activity_log_id
BEFORE INSERT ON Activity_Log
FOR EACH ROW
BEGIN
    IF :NEW.Log_ID IS NULL THEN
        :NEW.Log_ID := seq_activity_log.NEXTVAL;
    END IF;
END;
/


-- ============================================================
-- SECTION 2: INSERT SAMPLE DATA
-- ============================================================

INSERT INTO Hospitals VALUES
(1, 'Prayagraj Central Hospital', 'Sector 4', 200, '0532-2400001', 'pch@kumbh.gov.in', 20, 1, 1998);
INSERT INTO Hospitals VALUES
(2, 'Kumbh Medical Camp',         'Ghat 3',   100, '0532-2400002', 'kmc@kumbh.gov.in', 10, 1, 2025);

INSERT INTO Doctors VALUES
(101, 'Dr. Sharma', 'General',     1, '9988770101', 'sharma@kumbh.gov.in', 15, 'Available', 'Morning');
INSERT INTO Doctors VALUES
(102, 'Dr. Verma',  'Orthopedics', 1, '9988770102', 'verma@kumbh.gov.in',  10, 'Available', 'Afternoon');
INSERT INTO Doctors VALUES
(103, 'Dr. Singh',  'Cardiology',  2, '9988770103', 'singh@kumbh.gov.in',  20, 'On Leave',  'Morning');

INSERT INTO Police_Stations VALUES (1, 'Sangam Station',    'Sangam Ghat', '100', 'DSP Agarwal', 'Zone A');
INSERT INTO Police_Stations VALUES (2, 'Tent City Station', 'Sector 6',    '100', 'DSP Mishra',  'Zone B');

INSERT INTO Police_Officers VALUES (201, 'Inspector Raj', 'Inspector',     1, '9877000201', 'PKR201', 'Zone A', 1);
INSERT INTO Police_Officers VALUES (202, 'SI Priya',      'Sub-Inspector', 2, '9877000202', 'PKR202', 'Zone B', 1);

INSERT INTO Fire_Stations VALUES (1, 'Ghat Fire Post', 'Ghat Area', '9876500001', 'Officer Mehta',  5, 4);
INSERT INTO Fire_Stations VALUES (2, 'Tent Zone Post', 'Tent Zone', '9876500002', 'Officer Kapoor', 3, 3);

INSERT INTO Ghats VALUES (1, 'Sangam Ghat',  'Prayagraj', 50000, 'Open',       12000, 201);
INSERT INTO Ghats VALUES (2, 'Triveni Ghat', 'Zone B',    30000, 'Open',        8000, 202);
INSERT INTO Ghats VALUES (3, 'Dasashwamedh', 'Zone C',    20000, 'Restricted',  5000, NULL);

INSERT INTO Accommodation VALUES (1, 'Tent Block A', 'Zone 1', 50, 50, 'Standard', 500.00,  'Fan, Toilets, Drinking Water', 'Ramesh Kumar');
INSERT INTO Accommodation VALUES (2, 'Tent Block B', 'Zone 2', 30, 30, 'Deluxe',   1200.00, 'AC, Attached Bath, WiFi',      'Sunita Devi');

INSERT INTO Vendors VALUES (1, 'Ram Prasad Stall',  'Food',       'Ghat 1',   '9111000001', 'VND-001', '05:00-22:00', 'Active');
INSERT INTO Vendors VALUES (2, 'Shyam Handicrafts', 'Handicraft', 'Sector 3', '9111000002', 'VND-002', '08:00-20:00', 'Active');

INSERT INTO Transportation VALUES (1, 'Bus',   'Prayagraj - Varanasi', 50,  '08:00 AM', 'Ravi Kumar',     'UP32AB1234', 'Available', '12:00 PM');
INSERT INTO Transportation VALUES (2, 'Train', 'Prayagraj - Delhi',    200, '06:00 AM', 'Indian Railways', 'N/A',        'In-Route',  '01:00 PM');

INSERT INTO Emergency_Contact VALUES (1, 'Control Room', '112', 'Police',  1,    '24x7', 'control@kumbh.gov.in');
INSERT INTO Emergency_Contact VALUES (2, 'Fire Brigade', '101', 'Fire',    NULL, '24x7', 'fire@kumbh.gov.in');
INSERT INTO Emergency_Contact VALUES (3, 'Ambulance',    '108', 'Medical', NULL, '24x7', 'ambulance@kumbh.gov.in');

-- Note: Duplicate Pilgrim_ID=3 in original MySQL data is a bug; second row corrected to ID=4 here.
INSERT INTO Pilgrims VALUES (1, 'Ram Kumar', 45, 'M', '9000000001', 'Varanasi', 'B+', '123456789012', 'Indian', 'ram@email.com',   'Uttar Pradesh', SYSTIMESTAMP, 'Active');
INSERT INTO Pilgrims VALUES (2, 'Sita Devi', 60, 'F', '9000000002', 'Mathura',  'O+', '234567890123', 'Indian', 'sita@email.com',  'Uttar Pradesh', SYSTIMESTAMP, 'Active');
INSERT INTO Pilgrims VALUES (3, 'Arjun Rao', 35, 'M', '9000000003', 'Delhi',    'A+', '345678901234', 'Indian', 'arjun@email.com', 'Delhi',         SYSTIMESTAMP, 'Active');
INSERT INTO Pilgrims VALUES (4, 'Arn Rao',   35, 'M', '9000011103', 'Delhi',    'A+', '345678901235', 'Indian', 'arjun@email.com', 'Delhi',         SYSTIMESTAMP, 'Active');

INSERT INTO Pilgrim_Accommodation VALUES (1, 1, 1, TRUNC(SYSDATE), NULL);
INSERT INTO Pilgrim_Accommodation VALUES (2, 2, 2, TRUNC(SYSDATE), NULL);

INSERT INTO Pilgrim_Transportation VALUES (1, 1, 1, TRUNC(SYSDATE));
INSERT INTO Pilgrim_Transportation VALUES (2, 3, 2, TRUNC(SYSDATE));

INSERT INTO Incident_Reports VALUES (1, 'Pilgrim lost in crowd', 'High',   TRUNC(SYSDATE), 1, 1, 'Open',     NULL,           NULL,       'Sangam Ghat');
INSERT INTO Incident_Reports VALUES (2, 'Minor theft reported',  'Medium', TRUNC(SYSDATE), 2, 2, 'Resolved', TRUNC(SYSDATE), 'SI Priya', 'Tent Block B');

INSERT INTO Pilgrim_Treatments VALUES (1, 1, 101, 'Dehydration',      TRUNC(SYSDATE), 'ORS + IV Fluids + Rest',   NULL,           1);
INSERT INTO Pilgrim_Treatments VALUES (2, 2, 103, 'Chest Discomfort', TRUNC(SYSDATE), 'ECG + Cardiology Consult', TRUNC(SYSDATE), 2);

INSERT INTO Pilgrim_Purchases VALUES (1, 1, 1, 'Prasad', 50,  TRUNC(SYSDATE));
INSERT INTO Pilgrim_Purchases VALUES (2, 3, 2, 'Idol',   200, TRUNC(SYSDATE));

INSERT INTO Lost_And_Found VALUES (1, 'Wallet', 'Lost',  TRUNC(SYSDATE), 1, 'Brown leather wallet with ID cards', NULL,    NULL);
INSERT INTO Lost_And_Found VALUES (2, 'Bag',    'Found', TRUNC(SYSDATE), 2, 'Blue backpack with clothing',        'Ghat 2', NULL);
select * from pilgrim
fetch last 2 rows only;
COMMIT;


-- ============================================================
-- SECTION 3: TRIGGERS
-- ============================================================

-- TRIGGER 1: Decrease beds when pilgrim checks in
CREATE OR REPLACE TRIGGER trg_bed_checkin
AFTER INSERT ON Pilgrim_Accommodation
FOR EACH ROW
BEGIN
    UPDATE Accommodation
    SET Available_Beds = Available_Beds - 1
    WHERE Tent_ID = :NEW.Tent_ID;

    INSERT INTO Activity_Log (Action_Type, Description)
    VALUES ('CHECK-IN', 'Pilgrim ID ' || :NEW.Pilgrim_ID || ' checked into Tent ID ' || :NEW.Tent_ID);
END;
/

-- TRIGGER 2: Restore bed when pilgrim checks out
CREATE OR REPLACE TRIGGER trg_bed_checkout
AFTER UPDATE ON Pilgrim_Accommodation
FOR EACH ROW
BEGIN
    IF :NEW.Check_Out_Date IS NOT NULL AND :OLD.Check_Out_Date IS NULL THEN
        UPDATE Accommodation
        SET Available_Beds = Available_Beds + 1
        WHERE Tent_ID = :NEW.Tent_ID;

        INSERT INTO Activity_Log (Action_Type, Description)
        VALUES ('CHECK-OUT', 'Pilgrim ID ' || :NEW.Pilgrim_ID || ' checked out of Tent ID ' || :NEW.Tent_ID);
    END IF;
END;
/

-- TRIGGER 3: Log every new High priority incident
CREATE OR REPLACE TRIGGER trg_high_incident_log
AFTER INSERT ON Incident_Reports
FOR EACH ROW
BEGIN
    IF :NEW.Priority = 'High' THEN
        INSERT INTO Activity_Log (Action_Type, Description)
        VALUES ('HIGH INCIDENT', 'High priority incident at ' || :NEW.Incident_Location || ': ' || :NEW.Description);
    END IF;
END;
/

-- TRIGGER 4: Log whenever a new pilgrim is registered
CREATE OR REPLACE TRIGGER trg_pilgrim_registered
AFTER INSERT ON Pilgrims
FOR EACH ROW
BEGIN
    INSERT INTO Activity_Log (Action_Type, Description)
    VALUES ('PILGRIM ADDED', 'New pilgrim: ' || :NEW.Name || ' (' || :NEW.Blood_Group || ') from ' || :NEW.State);
END;
/


-- ============================================================
-- SECTION 4: STORED PROCEDURES
-- ============================================================

-- PROCEDURE 1: Register a pilgrim and assign accommodation
CREATE OR REPLACE PROCEDURE sp_register_pilgrim (
    p_id      IN NUMBER,
    p_name    IN VARCHAR2,
    p_age     IN NUMBER,
    p_gender  IN CHAR,
    p_contact IN VARCHAR2,
    p_city    IN VARCHAR2,
    p_tent_id IN NUMBER
)
AS
    v_available  NUMBER;
    v_booking_id NUMBER;
BEGIN
    SELECT Available_Beds INTO v_available
    FROM Accommodation WHERE Tent_ID = p_tent_id;

    IF v_available <= 0 THEN
        DBMS_OUTPUT.PUT_LINE('No beds available in this tent!');
    ELSE
        INSERT INTO Pilgrims (Pilgrim_ID, Name, Age, Gender, Contact_Number, City)
        VALUES (p_id, p_name, p_age, p_gender, p_contact, p_city);

        SELECT NVL(MAX(Booking_ID), 0) + 1 INTO v_booking_id
        FROM Pilgrim_Accommodation;

        INSERT INTO Pilgrim_Accommodation (Booking_ID, Pilgrim_ID, Tent_ID, Check_In_Date)
        VALUES (v_booking_id, p_id, p_tent_id, TRUNC(SYSDATE));

        DBMS_OUTPUT.PUT_LINE('Pilgrim ' || p_name || ' registered and bed booked successfully.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_register_pilgrim;
/

-- PROCEDURE 2: File an incident report
CREATE OR REPLACE PROCEDURE sp_file_incident (
    p_incident_id IN NUMBER,
    p_description IN VARCHAR2,
    p_priority    IN VARCHAR2,
    p_pilgrim_id  IN NUMBER,
    p_station_id  IN NUMBER,
    p_location    IN VARCHAR2
)
AS
BEGIN
    INSERT INTO Incident_Reports (Incident_ID, Description, Priority, Report_Date, Pilgrim_ID, Station_ID, Incident_Location)
    VALUES (p_incident_id, p_description, p_priority, TRUNC(SYSDATE), p_pilgrim_id, p_station_id, p_location);

    DBMS_OUTPUT.PUT_LINE('Incident filed with priority: ' || p_priority || ' at ' || p_location);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_file_incident;
/

-- PROCEDURE 3: Checkout a pilgrim (sets Check_Out_Date)
CREATE OR REPLACE PROCEDURE sp_checkout_pilgrim (
    p_pilgrim_id IN NUMBER,
    p_tent_id    IN NUMBER
)
AS
    v_bookings NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_bookings
    FROM Pilgrim_Accommodation
    WHERE Pilgrim_ID = p_pilgrim_id AND Tent_ID = p_tent_id AND Check_Out_Date IS NULL;

    IF v_bookings = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No active booking found for this pilgrim.');
    ELSE
        UPDATE Pilgrim_Accommodation
        SET Check_Out_Date = TRUNC(SYSDATE)
        WHERE Pilgrim_ID = p_pilgrim_id AND Tent_ID = p_tent_id AND Check_Out_Date IS NULL;

        UPDATE Pilgrims SET Status = 'Departed'
        WHERE Pilgrim_ID = p_pilgrim_id;

        DBMS_OUTPUT.PUT_LINE('Pilgrim ID ' || p_pilgrim_id || ' checked out and status updated to Departed.');
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_checkout_pilgrim;
/

-- Test procedures (enable DBMS_OUTPUT first: SET SERVEROUTPUT ON)
EXEC sp_register_pilgrim(5, 'Meena Joshi', 50, 'F', '9000000005', 'Jaipur', 1);
EXEC sp_file_incident(3, 'Medical emergency at Ghat', 'High', 1, 1, 'Sangam Ghat');
EXEC sp_checkout_pilgrim(2, 2);


-- ============================================================
-- SECTION 5: FUNCTIONS
-- ============================================================

-- FUNCTION 1: Get total incidents at a police station
CREATE OR REPLACE FUNCTION fn_incident_count (p_station_id IN NUMBER)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Incident_Reports WHERE Station_ID = p_station_id;
    RETURN v_count;
END fn_incident_count;
/

-- FUNCTION 2: Get available beds in a tent
CREATE OR REPLACE FUNCTION fn_available_beds (p_tent_id IN NUMBER)
RETURN NUMBER
IS
    v_beds NUMBER;
BEGIN
    SELECT Available_Beds INTO v_beds
    FROM Accommodation WHERE Tent_ID = p_tent_id;
    RETURN v_beds;
END fn_available_beds;
/

-- FUNCTION 3: Get total amount spent by a pilgrim
CREATE OR REPLACE FUNCTION fn_total_spent (p_pilgrim_id IN NUMBER)
RETURN NUMBER
IS
    v_total NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(Amount), 0) INTO v_total
    FROM Pilgrim_Purchases WHERE Pilgrim_ID = p_pilgrim_id;
    RETURN v_total;
END fn_total_spent;
/

-- Test functions
SELECT fn_incident_count(1) AS Incidents_At_Station_1 FROM DUAL;
SELECT fn_available_beds(1) AS Available_Beds_Tent_1  FROM DUAL;
SELECT fn_total_spent(1)    AS Total_Spent_Pilgrim_1  FROM DUAL;


-- ============================================================
-- SECTION 6: CURSORS (inside Anonymous Blocks / Procedures)
-- ============================================================

-- CURSOR 1: Show all pilgrims with accommodation and blood group
CREATE OR REPLACE PROCEDURE sp_show_pilgrim_stays
AS
    v_name    VARCHAR2(100);
    v_city    VARCHAR2(100);
    v_blood   VARCHAR2(5);
    v_tent    VARCHAR2(100);
    v_checkin DATE;

    CURSOR cur_stays IS
        SELECT p.Name, p.City, p.Blood_Group, a.Tent_Name, pa.Check_In_Date
        FROM Pilgrims p
        JOIN Pilgrim_Accommodation pa ON p.Pilgrim_ID = pa.Pilgrim_ID
        JOIN Accommodation a          ON pa.Tent_ID   = a.Tent_ID;
BEGIN
    OPEN cur_stays;
    LOOP
        FETCH cur_stays INTO v_name, v_city, v_blood, v_tent, v_checkin;
        EXIT WHEN cur_stays%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'Pilgrim: ' || v_name ||
            ' | City: ' || v_city ||
            ' | Blood: ' || v_blood ||
            ' | Tent: '  || v_tent  ||
            ' | Check-In: ' || TO_CHAR(v_checkin, 'YYYY-MM-DD')
        );
    END LOOP;
    CLOSE cur_stays;
END sp_show_pilgrim_stays;
/

-- CURSOR 2: List all High priority incidents
CREATE OR REPLACE PROCEDURE sp_show_high_incidents
AS
    v_pilgrim VARCHAR2(100);
    v_desc    VARCHAR2(200);
    v_loc     VARCHAR2(100);
    v_status  VARCHAR2(30);
    v_date    DATE;

    CURSOR cur_incidents IS
        SELECT p.Name, i.Description, i.Incident_Location, i.Status, i.Report_Date
        FROM Incident_Reports i
        JOIN Pilgrims p ON i.Pilgrim_ID = p.Pilgrim_ID
        WHERE i.Priority = 'High';
BEGIN
    OPEN cur_incidents;
    LOOP
        FETCH cur_incidents INTO v_pilgrim, v_desc, v_loc, v_status, v_date;
        EXIT WHEN cur_incidents%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'Pilgrim: ' || v_pilgrim ||
            ' | Incident: ' || v_desc  ||
            ' | Location: ' || v_loc   ||
            ' | Status: '   || v_status ||
            ' | Reported: ' || TO_CHAR(v_date, 'YYYY-MM-DD')
        );
    END LOOP;
    CLOSE cur_incidents;
END sp_show_high_incidents;
/

-- CURSOR 3: Show doctor workload with shift info
CREATE OR REPLACE PROCEDURE sp_doctor_workload
AS
    v_doctor   VARCHAR2(100);
    v_spec     VARCHAR2(100);
    v_shift    VARCHAR2(20);
    v_avail    VARCHAR2(20);
    v_patients NUMBER;

    CURSOR cur_doctors IS
        SELECT d.Name, d.Specialization, d.Shift, d.Availability_Status,
               COUNT(pt.Pilgrim_ID) AS Patients
        FROM Doctors d
        LEFT JOIN Pilgrim_Treatments pt ON d.Doctor_ID = pt.Doctor_ID
        GROUP BY d.Doctor_ID, d.Name, d.Specialization, d.Shift, d.Availability_Status;
BEGIN
    OPEN cur_doctors;
    LOOP
        FETCH cur_doctors INTO v_doctor, v_spec, v_shift, v_avail, v_patients;
        EXIT WHEN cur_doctors%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'Doctor: ' || v_doctor ||
            ' | Spec: '   || v_spec  ||
            ' | Shift: '  || v_shift ||
            ' | Status: ' || v_avail ||
            ' | Patients: ' || v_patients
        );
    END LOOP;
    CLOSE cur_doctors;
END sp_doctor_workload;
/

-- Test cursor procedures
EXEC sp_show_pilgrim_stays();
EXEC sp_show_high_incidents();
EXEC sp_doctor_workload();


-- ============================================================
-- SECTION 7: USEFUL SELECT QUERIES
-- ============================================================

-- Q1: All high priority incidents with location and status
SELECT Incident_ID, Description, Priority, Incident_Location, Status, Report_Date
FROM Incident_Reports WHERE Priority = 'High';

-- Q2: Doctor count per hospital with ICU info
SELECT h.Hospital_Name, h.ICU_Beds, COUNT(d.Doctor_ID) AS Doctor_Count
FROM Hospitals h
LEFT JOIN Doctors d ON h.Hospital_ID = d.Hospital_ID
GROUP BY h.Hospital_ID, h.Hospital_Name, h.ICU_Beds;

-- Q3: Available beds per tent with type and price
SELECT Tent_Name, Tent_Type, Total_Beds, Available_Beds, Price_Per_Day
FROM Accommodation ORDER BY Available_Beds DESC;

-- Q4: Pilgrims with lost items and descriptions
SELECT p.Name, p.Contact_Number, l.Item_Name, l.Item_Description, l.Status, l.Found_Location
FROM Pilgrims p JOIN Lost_And_Found l ON p.Pilgrim_ID = l.Pilgrim_ID;

-- Q5: Total spending per pilgrim
SELECT p.Name, p.City, SUM(pp.Amount) AS Total_Spent
FROM Pilgrims p
JOIN Pilgrim_Purchases pp ON p.Pilgrim_ID = pp.Pilgrim_ID
GROUP BY p.Pilgrim_ID, p.Name, p.City;

-- Q6: Doctors with shift, experience and patient count
SELECT d.Name AS Doctor, d.Specialization, d.Shift, d.Experience_Years,
       d.Availability_Status, COUNT(pt.Pilgrim_ID) AS Patients_Treated
FROM Doctors d
LEFT JOIN Pilgrim_Treatments pt ON d.Doctor_ID = pt.Doctor_ID
GROUP BY d.Doctor_ID, d.Name, d.Specialization, d.Shift, d.Experience_Years, d.Availability_Status;

-- Q7: Pilgrims with blood group and current status
SELECT Pilgrim_ID, Name, Age, Blood_Group, State, Contact_Number, Status
FROM Pilgrims ORDER BY Status, Name;

-- Q8: Ghat crowd vs capacity (occupancy rate)
--     Oracle uses ROUND() the same way as MySQL
SELECT Ghat_Name, Location, Capacity, Current_Crowd_Count,
       ROUND((Current_Crowd_Count / Capacity) * 100, 2) AS Occupancy_Percent,
       Status
FROM Ghats ORDER BY Occupancy_Percent DESC;

-- Q9: Officers on duty with their zone
--     Oracle: ON_DUTY = 1  (TRUE in MySQL)
SELECT o.Name, o.Officer_Rank, o.Badge_Number, o.Duty_Zone, s.Station_Name
FROM Police_Officers o
JOIN Police_Stations s ON o.Station_ID = s.Station_ID
WHERE o.On_Duty = 1;

-- Q10: View activity log
SELECT * FROM Activity_Log ORDER BY Log_Time DESC;

-- ============================================================
-- END OF ORACLE SCRIPT
-- ============================================================
