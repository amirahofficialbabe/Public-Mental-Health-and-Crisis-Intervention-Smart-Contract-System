# Public Mental Health and Crisis Intervention Smart Contract System

## Overview

This system provides a decentralized platform for coordinating public mental health services and crisis intervention. It consists of five interconnected smart contracts that manage different aspects of mental health care delivery.

## Contracts

### 1. Crisis Hotline Coordination (`crisis-hotline.clar`)
- Routes emergency mental health calls to available counselors
- Manages counselor availability and specializations
- Tracks call volume and response times
- Provides emergency escalation protocols

### 2. Mental Health Facility Capacity (`facility-capacity.clar`)
- Tracks available beds and services at public psychiatric facilities
- Manages facility registrations and capacity updates
- Provides real-time availability information
- Handles bed reservations and releases

### 3. Peer Support Program Management (`peer-support.clar`)
- Coordinates peer counseling and support group services
- Manages peer counselor certifications and availability
- Schedules support group sessions
- Tracks participant engagement and outcomes

### 4. Mental Health Medication Assistance (`medication-assistance.clar`)
- Helps low-income individuals access psychiatric medications
- Manages eligibility verification and assistance applications
- Tracks medication distribution and compliance
- Coordinates with pharmacies and healthcare providers

### 5. Community Mental Health Outreach (`community-outreach.clar`)
- Manages mobile crisis teams and community intervention programs
- Coordinates outreach activities and resource deployment
- Tracks community mental health metrics
- Manages volunteer and professional staff assignments

## Key Features

- **Decentralized Coordination**: No single point of failure
- **Real-time Updates**: Live tracking of resources and availability
- **Privacy Protection**: Sensitive data handled with appropriate access controls
- **Transparency**: Public visibility into system performance and resource allocation
- **Scalability**: Designed to handle city-wide or regional deployments

## Data Structures

### Common Types
- `principal`: User/organization identifiers
- `uint`: Numeric values for IDs, counts, timestamps
- `(string-ascii 50)`: Short text fields
- `(string-ascii 500)`: Longer descriptions
- `bool`: Status flags

### Status Codes
- `u0`: Inactive/Unavailable
- `u1`: Active/Available
- `u2`: Busy/Occupied
- `u3`: Emergency/Critical

## Error Codes

All contracts use consistent error handling:
- `u100`: Unauthorized access
- `u101`: Invalid input parameters
- `u102`: Resource not found
- `u103`: Resource unavailable
- `u104`: Operation failed
- `u105`: Insufficient permissions

## Usage

1. Deploy all five contracts to the Stacks blockchain
2. Initialize each contract with appropriate admin principals
3. Register facilities, counselors, and service providers
4. Begin coordinating mental health services through the contract interfaces

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

Tests cover all contract functions, error conditions, and integration scenarios.

## Security Considerations

- Admin functions are protected by principal verification
- Sensitive data access is restricted to authorized users
- All state changes are logged for audit purposes
- Emergency override functions are available for crisis situations
