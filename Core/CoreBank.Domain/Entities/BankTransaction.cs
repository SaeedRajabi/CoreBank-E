using CoreBank.Domain.Common;
using CoreBank.Domain.Enums;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class BankTransaction : AggregateRoot
{
    private BankTransaction(
        Guid id,
        string reference,
        TransactionType type,
        Guid? sourceAccountId,
        Guid? destinationAccountId,
        decimal amount,
        decimal fee,
        string description)
        : base(id)
    {
        Reference = reference;
        Type = type;
        SourceAccountId = sourceAccountId;
        DestinationAccountId = destinationAccountId;
        Amount = amount;
        Fee = fee;
        Description = description;
        Status = TransactionStatus.Pending;
        CreatedAtUtc = DateTime.UtcNow;
    }

    public string Reference { get; }
    public TransactionType Type { get; }
    public Guid? SourceAccountId { get; }
    public Guid? DestinationAccountId { get; }
    public decimal Amount { get; }
    public decimal Fee { get; }
    public string Description { get; }
    public TransactionStatus Status { get; private set; }
    public DateTime CreatedAtUtc { get; }
    public DateTime? CompletedAtUtc { get; private set; }
    public Guid? ReversedTransactionId { get; private set; }

    public static BankTransaction Create(
        string reference,
        TransactionType type,
        Guid? sourceAccountId,
        Guid? destinationAccountId,
        decimal amount,
        decimal fee,
        string description)
    {
        if (amount <= 0m)
        {
            throw new DomainException("مبلغ تراکنش باید بزرگ‌تر از صفر باشد.");
        }

        if (fee < 0m)
        {
            throw new DomainException("کارمزد نمی‌تواند منفی باشد.");
        }

        return new BankTransaction(
            Guid.NewGuid(),
            reference,
            type,
            sourceAccountId,
            destinationAccountId,
            amount,
            fee,
            description);
    }

    public void Complete()
    {
        if (Status != TransactionStatus.Pending)
        {
            throw new DomainException("تراکنش در وضعیت قابل تکمیل نیست.");
        }

        Status = TransactionStatus.Completed;
        CompletedAtUtc = DateTime.UtcNow;
    }

    public void Fail() => Status = TransactionStatus.Failed;

    public void Reverse(Guid reversalTransactionId)
    {
        if (Status != TransactionStatus.Completed)
        {
            throw new DomainException("فقط تراکنش تکمیل‌شده قابل برگشت است.");
        }

        Status = TransactionStatus.Reversed;
        ReversedTransactionId = reversalTransactionId;
    }
}
