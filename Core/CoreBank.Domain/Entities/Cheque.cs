using CoreBank.Domain.Common;
using CoreBank.Domain.Enums;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Cheque : AggregateRoot
{
    private Cheque(Guid id, Guid accountId, string serialNumber, string? sayadIdentifier, decimal amount, ChequeStatus status, DateTime issueDate, DateTime? dueDate, DateTime createdAtUtc)
        : base(id)
    {
        AccountId = accountId;
        SerialNumber = serialNumber;
        SayadIdentifier = sayadIdentifier;
        Amount = amount;
        Status = status;
        IssueDate = issueDate;
        DueDate = dueDate;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid AccountId { get; }
    public string SerialNumber { get; }
    public string? SayadIdentifier { get; private set; }
    public decimal Amount { get; }
    public ChequeStatus Status { get; private set; }
    public DateTime IssueDate { get; }
    public DateTime? DueDate { get; }
    public DateTime CreatedAtUtc { get; }

    public static Cheque Issue(Guid accountId, string serialNumber, decimal amount, DateTime issueDate, DateTime? dueDate, string? sayadIdentifier = null)
    {
        if (accountId == Guid.Empty) throw new DomainException("حساب معتبر نیست.");
        if (string.IsNullOrWhiteSpace(serialNumber)) throw new DomainException("سریال چک الزامی است.");
        if (amount <= 0) throw new DomainException("مبلغ چک باید مثبت باشد.");
        if (dueDate.HasValue && dueDate.Value.Date < issueDate.Date) throw new DomainException("تاریخ سررسید نمی‌تواند قبل از صدور باشد.");
        return new Cheque(Guid.NewGuid(), accountId, serialNumber.Trim(), sayadIdentifier?.Trim(), amount, ChequeStatus.Issued, issueDate.Date, dueDate?.Date, DateTime.UtcNow);
    }

    public static Cheque Rehydrate(Guid id, Guid accountId, string serialNumber, string? sayadIdentifier, decimal amount, ChequeStatus status, DateTime issueDate, DateTime? dueDate, DateTime createdAtUtc)
        => new(id, accountId, serialNumber, sayadIdentifier, amount, status, issueDate, dueDate ?? issueDate, createdAtUtc);

    public void Present()
    {
        if (Status != ChequeStatus.Issued) throw new DomainException("فقط چک صادر شده قابل ارائه است.");
        Status = ChequeStatus.Presented;
    }

    public void Clear()
    {
        if (Status != ChequeStatus.Presented) throw new DomainException("فقط چک ارائه شده قابل پاس شدن است.");
        Status = ChequeStatus.Cleared;
    }

    public void Return()
    {
        if (Status != ChequeStatus.Presented) throw new DomainException("فقط چک ارائه شده قابل برگشت است.");
        Status = ChequeStatus.Returned;
    }

    public void Block()
    {
        if (Status == ChequeStatus.Cleared || Status == ChequeStatus.Returned) throw new DomainException("چک پاس یا برگشت شده قابل مسدودی نیست.");
        Status = ChequeStatus.Blocked;
    }

    public void SetSayad(string sayad)
    {
        if (string.IsNullOrWhiteSpace(sayad)) throw new DomainException("شناسه صیاد الزامی است.");
        SayadIdentifier = sayad.Trim();
    }
}
