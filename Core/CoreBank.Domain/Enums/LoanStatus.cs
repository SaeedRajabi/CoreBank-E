namespace CoreBank.Domain.Enums;

public enum LoanStatus : byte
{
    Current = 1,
    PastDue = 2,
    Delinquent = 3,
    Doubtful = 4,
    Closed = 5
}
