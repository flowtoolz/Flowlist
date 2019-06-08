import CloudKit

extension Error
{
    var ckReadable: ReadableError
    {
        return ckError?.readable ?? readable
    }
    
    var ckError: CKError? { return self as? CKError }
}

extension CKError
{
    var readable: ReadableError { return .message(ckMessage) }
    
    var ckMessage: String
    {
        if let underlyingError = underlyingError
        {
            return codeString + " - \(underlyingError.localizedDescription)"
        }
        else
        {
            return codeString
        }
    }
    
    var codeString: String
    {
        switch code
        {
        case .internalError: return "Internal error"
        case .partialFailure: return "Partial Failure"
        case .networkUnavailable: return "Network Unavailable"
        case .networkFailure: return "Network Failure"
        case .badContainer: return "Bad Container"
        case .serviceUnavailable: return "Service Unavailable"
        case .requestRateLimited: return "Request Rate Limited"
        case .missingEntitlement: return "Missing Entitlement"
        case .notAuthenticated: return "Not Authenticated"
        case .permissionFailure: return "Permission Failure"
        case .unknownItem: return "Unknown Item"
        case .invalidArguments: return "InvalidArguments"
        case .resultsTruncated: return "Results Truncated"
        case .serverRecordChanged: return "Server Record Changed"
        case .serverRejectedRequest: return "Server Rejected Request"
        case .assetFileNotFound: return "Asset File Not Found"
        case .assetFileModified: return "Asset File Modified"
        case .incompatibleVersion: return "Incompatible Version"
        case .constraintViolation: return "Constraint Violation"
        case .operationCancelled: return "Operation Cancelled"
        case .changeTokenExpired: return "Change Token Expired"
        case .batchRequestFailed: return "Batch Request Failed"
        case .zoneBusy: return "Zone Busy"
        case .badDatabase: return "Bad Database"
        case .quotaExceeded: return "Quota Exceeded"
        case .zoneNotFound: return "Zone Not Found"
        case .limitExceeded: return "Limit Exceeded"
        case .userDeletedZone: return "User Deleted Zone"
        case .tooManyParticipants: return "Too Many Participants"
        case .alreadyShared: return "Already Shared"
        case .referenceViolation: return "Reference Violation"
        case .managedAccountRestricted: return "Managed Account Restricted"
        case .participantMayNeedVerification: return "Participant May Need Verification"
        case .serverResponseLost: return "Server Response Lost"
        case .assetNotAvailable: return "Asset Not Available"
        @unknown default: return "Unknown Enum Case"
        }
    }
    
    var underlyingError: NSError?
    {
        return errorUserInfo[NSUnderlyingErrorKey] as? NSError
    }
}
