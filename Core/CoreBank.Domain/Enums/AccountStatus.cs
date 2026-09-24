namespace CoreBank.Domain.Enums;

public enum AccountStatus : byte
{
    Active = 1,
    Dormant = 2,
    Frozen = 3,
    Closed = 4
}
