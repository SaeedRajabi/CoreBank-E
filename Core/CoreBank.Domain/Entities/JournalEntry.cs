using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed record JournalLine(
    Guid? AccountId,
    string LedgerAccountCode,
    decimal Debit,
    decimal Credit,
    string Description)
{
    public void Validate()
    {
        if (Debit < 0m || Credit < 0m || (Debit == 0m && Credit == 0m) || (Debit > 0m && Credit > 0m))
        {
            throw new DomainException("هر سطر دفترکل باید دقیقاً بدهکار یا بستانکار باشد.");
        }
    }
}

public sealed class JournalEntry : AggregateRoot
{
    private JournalEntry(Guid id, Guid transactionId, string description, IReadOnlyCollection<JournalLine> lines)
        : base(id)
    {
        TransactionId = transactionId;
        Description = description;
        Lines = lines;
        EntryDateUtc = DateTime.UtcNow;
    }

    public Guid TransactionId { get; }
    public string Description { get; }
    public IReadOnlyCollection<JournalLine> Lines { get; }
    public DateTime EntryDateUtc { get; }

    public static JournalEntry Create(Guid transactionId, string description, IEnumerable<JournalLine> lines)
    {
        var materialized = lines.ToArray();
        if (materialized.Length < 2)
        {
            throw new DomainException("ثبت دفترکل حداقل به دو سطر نیاز دارد.");
        }

        foreach (var line in materialized)
        {
            line.Validate();
        }

        var debit = materialized.Sum(x => x.Debit);
        var credit = materialized.Sum(x => x.Credit);
        if (debit != credit)
        {
            throw new DomainException("دفترکل نامتوازن است.");
        }

        return new JournalEntry(Guid.NewGuid(), transactionId, description, materialized);
    }
}
