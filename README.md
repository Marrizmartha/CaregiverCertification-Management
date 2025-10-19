# CaregiverCertification - Professional Caregiver Credential Management

A blockchain-based system for managing caregiver certifications and training records on Stacks.

## Features

- Issue professional caregiver certifications
- Track training records and completion hours
- Certificate renewal management
- Certification revocation capabilities
- Real-time validity checking

## Contract Functions

### Public Functions
- `issue-certification`: Issue a new caregiver certification
- `add-training-record`: Add training completion record
- `renew-certification`: Renew an existing certification
- `revoke-certification`: Revoke a caregiver's certification

### Read-Only Functions
- `get-caregiver`: Retrieve caregiver information
- `get-training-record`: Get training record details
- `get-renewal`: Get renewal record information
- `is-certification-valid`: Check if certification is currently valid
- `get-total-training-hours`: Get total training hours for caregiver

## Use Cases

- Healthcare facility credential verification
- Training compliance tracking
- Professional certification management
- Audit trail for caregiver qualifications

## Testing

Run tests with Clarinet:
```bash
clarinet test
```

## License

MIT License