using CoreBank.Domain.Common;
using CoreBank.Domain.Enums;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Loan : AggregateRoot
{
    private Loan(Guid id, Guid customerId, decimal principal, decimal annualRate, int termMonths, LoanStatus status, DateTime requestedAtUtc, DateTime? approvedAtUtc)
        : base(id)
    {
        CustomerId = customerId;
        Principal = principal;
        AnnualRate = annualRate;
        TermMonths = termMonths;
        Status = status;
        RequestedAtUtc = requestedAtUtc;
        ApprovedAtUtc = approvedAtUtc;
    }

    public Guid CustomerId { get; }
    public decimal Principal { get; }
    public decimal AnnualRate { get; }
    public int TermMonths { get; }
    public LoanStatus Status { get; private set; }
    public DateTime RequestedAtUtc { get; }
    public DateTime? ApprovedAtUtc { get; private set; }

    public static Loan Request(Guid customerId, decimal principal, decimal annualRate, int termMonths)
    {
        if (customerId == Guid.Empty) throw new DomainException("مشتری معتبر نیست.");
        if (principal <= 0) throw new DomainException("مبلغ تسهیلات باید مثبت باشد.");
        if (annualRate < 0 || annualRate > 1) throw new DomainException("نرخ سالانه باید بین ۰ و ۱ باشد (مثلاً ۰.۱۸ برای ۱۸٪).");
        if (termMonths < 1 || termMonths > 120) throw new DomainException("مدت بازپرداخت باید ۱ تا ۱۲۰ ماه باشد.");
        return new Loan(Guid.NewGuid(), customerId, principal, annualRate, termMonths, LoanStatus.Current, DateTime.UtcNow, null);
    }

    public static Loan Rehydrate(Guid id, Guid customerId, decimal principal, decimal annualRate, int termMonths, LoanStatus status, DateTime requestedAtUtc, DateTime? approvedAtUtc)
    {
        var loan = new Loan(id, customerId, principal, annualRate, termMonths, status, requestedAtUtc, approvedAtUtc);
        return loan;
    }

    public void Approve()
    {
        if (Status != LoanStatus.Current) throw new DomainException("فقط تسهیلات جاری قابل تایید است.");
        Status = LoanStatus.Current;
        ApprovedAtUtc = DateTime.UtcNow;
    }

    public void MarkPastDue() => Status = LoanStatus.PastDue;
    public void MarkDelinquent() => Status = LoanStatus.Delinquent;
    public void MarkDoubtful() => Status = LoanStatus.Doubtful;
    public void Close()
    {
        if (Status == LoanStatus.Closed) throw new DomainException("تسهیلات قبلاً بسته شده است.");
        Status = LoanStatus.Closed;
    }

    public decimal MonthlyInstallment()
    {
        if (AnnualRate == 0) return Math.Round(Principal / TermMonths, 2);
        var monthlyRate = AnnualRate / 12m;
        var pow = (decimal)Math.Pow((double)(1 + monthlyRate), TermMonths);
        return Math.Round(Principal * monthlyRate * pow / (pow - 1), 2);
    }

    public decimal TotalPayable() => MonthlyInstallment() * TermMonths;
}
