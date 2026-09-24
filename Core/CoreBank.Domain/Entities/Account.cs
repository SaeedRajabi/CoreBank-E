using CoreBank.Domain.Common;
using CoreBank.Domain.Enums;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Account : AggregateRoot
{
    private Account(
        Guid id,
        Guid customerId,
        string accountNumber,
        string iban,
        string? cardNumber,
        AccountType type,
        decimal minimumBalance,
        decimal balance,
        long version,
        AccountStatus status)
        : base(id)
    {
        CustomerId = customerId;
        AccountNumber = accountNumber;
        Iban = iban;
        CardNumber = cardNumber;
        Type = type;
        MinimumBalance = minimumBalance;
        Balance = balance;
        Version = version;
        Status = status;
        _openedAtUtc = DateTime.UtcNow;
    }

    public Guid CustomerId { get; }
    public string AccountNumber { get; }
    public string Iban { get; }
    public string? CardNumber { get; }
    public AccountType Type { get; }
    public AccountStatus Status { get; private set; }
    public decimal Balance { get; private set; }
    public decimal MinimumBalance { get; }
    public long Version { get; private set; }
    public DateTime OpenedAtUtc => _openedAtUtc;
    public DateTime? ClosedAtUtc { get; private set; }

    public static Account Open(
        Guid customerId,
        string accountNumber,
        string iban,
        string? cardNumber,
        AccountType type,
        decimal minimumBalance = 0m)
    {
        if (customerId == Guid.Empty)
        {
            throw new DomainException("مشتری حساب معتبر نیست.");
        }

        if (string.IsNullOrWhiteSpace(accountNumber))
        {
            throw new DomainException("شماره حساب الزامی است.");
        }

        if (minimumBalance < 0)
        {
            throw new DomainException("کف موجودی نمی‌تواند منفی باشد.");
        }

        return new Account(
            Guid.NewGuid(),
            customerId,
            accountNumber,
            iban,
            cardNumber,
            type,
            minimumBalance,
            0m,
            0L,
            AccountStatus.Active);
    }

    public static Account Rehydrate(
        Guid id,
        Guid customerId,
        string accountNumber,
        string iban,
        string? cardNumber,
        AccountType type,
        AccountStatus status,
        decimal balance,
        decimal minimumBalance,
        long version,
        DateTime openedAtUtc,
        DateTime? closedAtUtc)
    {
        var account = new Account(
            id,
            customerId,
            accountNumber,
            iban,
            cardNumber,
            type,
            minimumBalance,
            balance,
            version,
            status)
        {
            ClosedAtUtc = closedAtUtc
        };
        account._openedAtUtc = openedAtUtc;
        return account;
    }

    private DateTime _openedAtUtc;

    public void Credit(decimal amount)
    {
        EnsureOperational();
        EnsurePositive(amount);
        Balance += amount;
    }

    public void Debit(decimal amount)
    {
        EnsureOperational();
        EnsurePositive(amount);
        if (Balance - amount < MinimumBalance)
        {
            throw new DomainException("موجودی پس از برداشت از کف مجاز کمتر می‌شود.");
        }

        Balance -= amount;
    }

    public void Freeze() => Status = AccountStatus.Frozen;

    public void Activate() => Status = AccountStatus.Active;

    public void Close()
    {
        if (Balance != 0m)
        {
            throw new DomainException("حساب دارای مانده را نمی‌توان بست.");
        }

        Status = AccountStatus.Closed;
        ClosedAtUtc = DateTime.UtcNow;
    }

    public void IncrementVersion() => Version++;

    private void EnsureOperational()
    {
        if (Status is AccountStatus.Frozen or AccountStatus.Closed)
        {
            throw new DomainException("حساب در وضعیت عملیاتی نیست.");
        }
    }

    private static void EnsurePositive(decimal amount)
    {
        if (amount <= 0m)
        {
            throw new DomainException("مبلغ باید بزرگ‌تر از صفر باشد.");
        }
    }
}
