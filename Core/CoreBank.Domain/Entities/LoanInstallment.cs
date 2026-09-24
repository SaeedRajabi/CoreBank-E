using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class LoanInstallment : AggregateRoot
{
    private LoanInstallment(Guid id, Guid loanId, int installmentNumber, DateTime dueDate, decimal amount, decimal paidAmount, bool isPaid, DateTime? paidAtUtc)
        : base(id)
    {
        LoanId = loanId;
        InstallmentNumber = installmentNumber;
        DueDate = dueDate;
        Amount = amount;
        PaidAmount = paidAmount;
        IsPaid = isPaid;
        PaidAtUtc = paidAtUtc;
    }

    public Guid LoanId { get; }
    public int InstallmentNumber { get; }
    public DateTime DueDate { get; }
    public decimal Amount { get; }
    public decimal PaidAmount { get; private set; }
    public bool IsPaid { get; private set; }
    public DateTime? PaidAtUtc { get; private set; }

    public static LoanInstallment Create(Guid loanId, int number, DateTime dueDate, decimal amount)
    {
        if (loanId == Guid.Empty) throw new DomainException("شناسه تسهیلات معتبر نیست.");
        if (number < 1) throw new DomainException("شماره قسط معتبر نیست.");
        if (amount <= 0) throw new DomainException("مبلغ قسط باید مثبت باشد.");
        return new LoanInstallment(Guid.NewGuid(), loanId, number, dueDate.Date, amount, 0m, false, null);
    }

    public static LoanInstallment Rehydrate(Guid id, Guid loanId, int number, DateTime dueDate, decimal amount, decimal paidAmount, bool isPaid, DateTime? paidAtUtc)
        => new(id, loanId, number, dueDate, amount, paidAmount, isPaid, paidAtUtc);

    public void Pay(decimal amount)
    {
        if (IsPaid) throw new DomainException("قسط قبلاً پرداخت شده است.");
        if (amount < Amount) throw new DomainException($"مبلغ پرداختی باید {Amount:N0} ریال باشد.");
        PaidAmount = amount;
        IsPaid = true;
        PaidAtUtc = DateTime.UtcNow;
    }
}
