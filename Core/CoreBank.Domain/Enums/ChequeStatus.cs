namespace CoreBank.Domain.Enums;

public enum ChequeStatus : byte
{
    Issued = 1,
    Presented = 2,
    Cleared = 3,
    Returned = 4,
    Blocked = 5
}