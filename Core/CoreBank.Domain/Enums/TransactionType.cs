namespace CoreBank.Domain.Enums;

public enum TransactionType : byte
{
    Deposit = 1,
    Withdrawal = 2,
    InternalTransfer = 3,
    CardToCard = 4,
    Paya = 5,
    Satna = 6,
    LoanInstallment = 7,
    Fee = 8,
    Reversal = 9
}
