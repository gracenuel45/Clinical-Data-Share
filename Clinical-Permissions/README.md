# Clinical Data Sharing Smart Contract

## Overview

This smart contract enables secure, permissioned sharing of anonymized clinical data with comprehensive access control, data integrity verification, and complete audit trails. The contract is designed to facilitate collaborative medical research while maintaining strict privacy protections and regulatory compliance.

## Features

### Core Functionality
- **Secure Data Upload**: Upload anonymized clinical data with metadata and consent tracking
- **Access Control**: Granular permission system with time-based access controls
- **Research Study Management**: Register and manage research studies with ethics approval tracking
- **Researcher Verification**: Comprehensive researcher credential verification system
- **Institution Management**: Verify and manage participating institutions
- **Consent Management**: Record, track, and manage patient consent with withdrawal capabilities
- **Audit Trails**: Complete logging of all data access and operations
- **Data Integrity**: Hash-based data integrity verification
- **Usage Analytics**: Track data usage, citations, and impact metrics

### Security Features
- Role-based access control with multiple permission levels
- Time-bound access permissions with automatic expiration
- Emergency contract pause functionality
- Consent withdrawal mechanisms
- Data provider control over access revocation

## Contract Structure

### Key Data Structures

#### Clinical Data
- Data hash for integrity verification
- Anonymization level (1-5 scale)
- Data type and study category
- Upload timestamp and provider information
- Consent status and access tracking
- Comprehensive metadata storage

#### Research Studies
- Study identification and purpose
- Principal investigator and institution
- Required data types and ethics approval
- Timeline and participant information
- Status tracking

#### Access Permissions
- Researcher-specific data access rights
- Permission levels and expiration dates
- Study association and usage restrictions
- Grantor tracking and activation status

#### Researcher Verification
- Institutional affiliation verification
- Credential and ethics clearance tracking
- Research area specialization
- Reputation scoring system

## Public Functions

### Data Management

#### `upload-clinical-data`
```clarity
(upload-clinical-data data-hash anonymization-level data-type study-category data-size metadata consent-id)
```
Upload anonymized clinical data with associated metadata and consent verification.

**Parameters:**
- `data-hash`: SHA-256 hash of the data file
- `anonymization-level`: Level of anonymization (1-5)
- `data-type`: Type of clinical data
- `study-category`: Research category classification
- `data-size`: Size of data in bytes
- `metadata`: Additional descriptive metadata
- `consent-id`: Associated consent record identifier

**Returns:** Data ID for the uploaded record

#### `access-clinical-data`
```clarity
(access-clinical-data data-id access-type ip-hash)
```
Access clinical data with proper authorization and audit logging.

**Parameters:**
- `data-id`: Unique identifier of the data record
- `access-type`: Type of access (view, download, etc.)
- `ip-hash`: Hashed IP address for audit trail

**Returns:** Data hash for integrity verification

### Study Management

#### `register-study`
```clarity
(register-study study-name institution study-purpose required-data-types ethics-approval end-date participant-count)
```
Register a new research study with comprehensive details.

**Parameters:**
- `study-name`: Name of the research study
- `institution`: Conducting institution identifier
- `study-purpose`: Detailed study purpose and objectives
- `required-data-types`: List of required data types
- `ethics-approval`: Ethics committee approval reference
- `end-date`: Study completion timestamp
- `participant-count`: Expected number of participants

**Returns:** Study ID for the registered study

### Access Management

#### `request-data-access`
```clarity
(request-data-access data-id study-id access-duration access-purpose usage-restrictions)
```
Request access to specific clinical data for research purposes.

**Parameters:**
- `data-id`: Target data record identifier
- `study-id`: Associated research study ID
- `access-duration`: Duration of access in seconds
- `access-purpose`: Detailed purpose of data access
- `usage-restrictions`: Any specific usage limitations

**Returns:** Boolean indicating approval status

#### `revoke-access`
```clarity
(revoke-access data-id researcher)
```
Revoke data access permissions for a specific researcher.

### Verification Functions

#### `verify-researcher`
```clarity
(verify-researcher researcher institution credentials research-areas ethics-clearance)
```
Verify and register researcher credentials (admin only).

#### `register-institution`
```clarity
(register-institution institution-id institution-name verification-authority contact-info compliance-status)
```
Register and verify an institution (admin only).

### Consent Management

#### `record-consent`
```clarity
(record-consent consent-id consent-scope data-types-consented withdrawal-allowed expiry-date consent-version)
```
Record patient consent for data sharing.

#### `withdraw-consent`
```clarity
(withdraw-consent consent-id)
```
Withdraw previously given consent.

### Analytics and Tracking

#### `update-citation-count`
```clarity
(update-citation-count data-id citation-increment)
```
Update citation count for impact tracking.

## Read-Only Functions

### Information Retrieval
- `get-data-info`: Retrieve clinical data information
- `get-study-info`: Get research study details
- `get-researcher-info`: Access researcher credentials
- `get-institution-info`: Institution verification details
- `get-usage-stats`: Data usage statistics
- `get-consent-status`: Consent record status
- `get-contract-stats`: Overall contract statistics

### Verification Functions
- `is-verified-researcher`: Check researcher verification status
- `has-active-access`: Verify active data access permissions
- `verify-data-integrity`: Validate data integrity using hash comparison

## Access Control

### Permission Levels
- **Level 1**: Basic data access (view only)
- **Level 2**: Download permissions
- **Level 3**: Extended access with analysis tools
- **Level 4**: Full research collaboration access
- **Level 5**: Administrative access to data management

### Role-Based Access
- **Contract Owner**: Full administrative control
- **Data Providers**: Upload and manage their contributed data
- **Verified Researchers**: Access data based on permissions and study requirements
- **Institutions**: Manage affiliated researchers and studies

## Security Considerations

### Data Protection
- All clinical data must be anonymized before upload
- Hash-based integrity verification prevents tampering
- Time-bound access prevents indefinite data exposure
- Consent tracking ensures compliance with patient wishes

### Access Monitoring
- Complete audit trail of all data access
- IP address tracking for security monitoring
- Usage pattern analysis for anomaly detection
- Regular access review and permission updates

### Emergency Controls
- Contract pause functionality for security incidents
- Immediate access revocation capabilities
- Consent withdrawal mechanisms
- Administrative override controls

## Compliance Features

### Regulatory Compliance
- Ethics approval tracking for all studies
- Institutional verification requirements
- Researcher credential validation
- Patient consent management with withdrawal rights

### Audit Requirements
- Immutable access logs
- Timestamp tracking for all operations
- User identification and verification
- Purpose tracking for all data access

## Usage Guidelines

### For Data Providers
1. Ensure proper anonymization before upload
2. Obtain valid consent with appropriate scope
3. Provide accurate metadata and categorization
4. Monitor access patterns and usage statistics

### For Researchers
1. Complete institutional verification process
2. Register research studies with ethics approval
3. Request access only for legitimate research purposes
4. Comply with usage restrictions and cite data sources
5. Update citation counts for impact tracking

### For Institutions
1. Maintain verified status and compliance
2. Ensure researcher credential accuracy
3. Monitor affiliated research activities
4. Maintain ethics review processes

## Error Handling

The contract includes comprehensive error handling with specific error codes:

- `ERR-UNAUTHORIZED-ACCESS`: Insufficient permissions
- `ERR-INVALID-DATA-ID`: Invalid or malformed data identifier
- `ERR-DATA-ALREADY-EXISTS`: Duplicate data upload attempt
- `ERR-INVALID-PERMISSION`: Permission parameters out of range
- `ERR-INVALID-RESEARCHER`: Unverified or invalid researcher
- `ERR-ACCESS-EXPIRED`: Time-bound access has expired
- `ERR-CONSENT-REVOKED`: Patient consent withdrawn
- `ERR-HASH-MISMATCH`: Data integrity verification failed

## Technical Specifications

### Data Limits
- Maximum data size: 1,000,000 bytes per record
- Minimum access duration: 24 hours
- Maximum access duration: 1 year
- Metadata limit: 500 characters

### Storage Efficiency
- Hash-based data references minimize on-chain storage
- Structured data maps for efficient queries
- Optimized permission checking algorithms
- Minimal redundant data storage