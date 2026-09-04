# Kumbh Management DBMS

A comprehensive Database Management System designed for managing operations during the Kumbh Mela, one of the largest peaceful gatherings in the world. This system helps administrators manage pilgrim data, accommodations, transportation, medical services, security, and various other aspects of the event.

## About

The Kumbh Management DBMS is a relational database solution that provides structured data management for the complex logistics of the Kumbh Mela. With millions of pilgrims attending, efficient management of resources, services, and safety is crucial. This system organizes data related to:

- Pilgrim registrations and tracking
- Accommodation assignments (tents, hotels, dharamshalas)
- Transportation management (buses, trains, special vehicles)
- Medical facilities and emergency services
- Security and police deployment
- Fire safety stations
- Lost and found operations
- Vendor and commercial activity management
- Incident reporting and tracking
- Pilgrim purchases and treatments
- Ghats (bathing sites) management
- Activity logging for audit trails

## Features

- **Comprehensive Schema**: 17 interconnected tables covering all aspects of Kumbh Mela management
- **Data Integrity**: Proper foreign key relationships and constraints
- **Scalable Design**: Handles large volumes of pilgrim data efficiently
- **Audit Trail**: Activity logging for all system operations
- **Modular Structure**: Separate tables for different functional areas
- **Reference Data**: Standardized lists for locations, services, and contacts
- **Emergency Management**: Dedicated tables for medical, police, and fire services
- **Transaction Tracking**: Records for purchases, treatments, and other transactions

## Database Schema Overview

### Core Entity Tables
- **PILGRIMS**: Main pilgrim registration information
- **ACCOMMODATION**: Lodging facilities details
- **GHATS**: Bathing sites at the river
- **TRANSPORTATION**: Available transport options
- **HOSPITALS**: Medical facilities
- **POLICE_STATIONS**: Security outposts
- **FIRE_STATIONS**: Fire safety points
- **VENDORS**: Commercial service providers

### Management Tables
- **PILGRIM_ACCOMMODATION**: Pilgrim-to-accommodation assignments
- **PILGRIM_TRANSPORTATION**: Transport allocations
- **PILGRIM_TREATMENTS**: Medical treatment records
- **PILGRIM_PURCHASES**: Commercial transactions
- **LOST_AND_FOUND**: Lost items reporting
- **INCIDENT_REPORTS**: Security/safety incidents
- **EMERGENCY_CONTACT**: Pilgrim emergency contacts

### Reference & Audit Tables
- **ACTIVITY_LOG**: System audit trail
- Various lookup tables for standardized data

## Installation & Setup

### Prerequisites
- Oracle Database (or compatible SQL database)
- SQL*Plus or SQL Developer
- Basic SQL knowledge

### Setup Instructions
1. **Create Database User** (if needed):
   ```sql
   CREATE USER kumbh_admin IDENTIFIED BY your_password;
   GRANT CONNECT, RESOURCE, DBA TO kumbh_admin;
   ```

2. **Connect to Database**:
   ```sql
   CONNECT kumbh_admin/your_password
   ```

3. **Run the Setup Script**:
   ```sql
   @SmartKumbh.sql
   ```
   This script will:
   - Drop existing tables (if any)
   - Create all 17 tables with proper relationships
   - Insert sample/reference data where applicable
   - Create sequences for auto-incrementing IDs

4. **Verify Installation**:
   ```sql
   SELECT table_name FROM user_tables;
   SELECT sequence_name FROM user_sequences;
   ```

## Usage

### Common Queries Examples

**Find all pilgrims at a specific ghat:**
```sql
SELECT p.*, g.ghat_name
FROM PILGRIMS p
JOIN PILGRIM_ACCOMMODATION pa ON p.pilgrim_id = pa.pilgrim_id
JOIN ACCOMMODATION a ON pa.accommodation_id = a.accommodation_id
JOIN GHATS g ON a.ghat_id = g.ghat_id
WHERE g.ghat_name = 'Sangam Ghat';
```

**Check medical treatments given:**
```sql
SELECT p.pilgrim_name, h.hospital_name, pt.treatment_type, pt.treatment_date
FROM PILGRIMS p
JOIN PILGRIM_TREATMENTS pt ON p.pilgrim_id = pt.pilgrim_id
JOIN HOSPITALS h ON pt.hospital_id = h.hospital_id
ORDER BY pt.treatment_date DESC;
```

**View lost and found items:**
```sql
SELECT lf.item_description, p.pilgrim_name, lf.status
FROM LOST_AND_FOUND lf
LEFT JOIN PILGRIMS p ON lf.pilgrim_id = p.pilgrim_id
WHERE lf.status = 'LOST';
```

**Get activity log for audit:**
```sql
SELECT * FROM ACTIVITY_LOG
WHERE log_timestamp >= SYSDATE - 7
ORDER BY log_timestamp DESC;
```

## Contributing

We welcome contributions to improve the Kumbh Management DBMS! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Commit your changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request**

### Contribution Guidelines
- Follow existing SQL formatting and naming conventions
- Add comments for complex logic
- Ensure data integrity with proper constraints
- Test your changes with sample data
- Update documentation as needed

### Reporting Issues
Please use the GitHub Issues tracker to report bugs or suggest enhancements.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for better management systems at large religious gatherings
- Based on real-world requirements for Kumbh Mela operations
- Designed to be adaptable for similar large-scale events

## Contact

For questions or suggestions, please open an issue in this repository or contact the repository owner.

---

*Note: This is an educational/sample project. For actual deployment at events like Kumbh Mela, additional security measures, performance optimizations, and local regulatory compliance would be required.*
