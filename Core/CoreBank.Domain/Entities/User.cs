using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;
using CoreBank.Domain.ValueOBJs;

namespace CoreBank.Domain.Entities;

public sealed class User : AggregateRoot
{

    #region Properties

    public string Username { get; private set; }
    public Password PasswordHash { get; private set; }
    public string DisplayName { get; private set; }
    public Email Email { get; private set; }
    public string? PhoneNumber { get; private set; }
    public bool IsActive { get; private set; }
    public bool IsLockedOut { get; private set; }
    public int FailedAttempts { get; private set; }
    public DateTime? LockoutEndUtc { get; private set; }
    public DateTime? LastLoginUtc { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime UpdatedAtUtc { get; private set; }
    #endregion

    #region CTORs

    private User(
        Guid id,
        string username,
        Password passwordHash,
        string displayName,
        Email email,
        string? phoneNumber,
        bool isActive,
        bool isLockedOut,
        int failedAttempts,
        DateTime? lockoutEndUtc,
        DateTime? lastLoginUtc,
        DateTime createdAtUtc,
        DateTime updatedAtUtc)
        : base(id)
    {
        Username = username;
        PasswordHash = passwordHash;
        DisplayName = displayName;
        Email = email;
        PhoneNumber = phoneNumber;
        IsActive = isActive;
        IsLockedOut = isLockedOut;
        FailedAttempts = failedAttempts;
        LockoutEndUtc = lockoutEndUtc;
        LastLoginUtc = lastLoginUtc;
        CreatedAtUtc = createdAtUtc;
        UpdatedAtUtc = updatedAtUtc;
    }
    #endregion

    #region Factories Method
    public static User Create(
        string username,
        string password,
        string displayName,
        string? email = null,
        string? phoneNumber = null)
    {
        if (string.IsNullOrWhiteSpace(username) || username.Length < 3)
            throw new DomainException("نام کاربری باید حداقل ۳ کاراکتر باشد.");

        if (string.IsNullOrWhiteSpace(displayName))
            throw new DomainException("نام نمایشی الزامی است.");

        return new User(
            Guid.NewGuid(),
            username.Trim().ToLowerInvariant(),
            Password.Create(password),
            displayName.Trim(),
            Email.Create(email!.Trim().ToLowerInvariant()),
            phoneNumber?.Trim(),
            isActive: true,
            isLockedOut: false,
            failedAttempts: 0,
            lockoutEndUtc: null,
            lastLoginUtc: null,
            DateTime.UtcNow,
            DateTime.UtcNow);
    }

    public static User Rehydrate(
        Guid id,
        string username,
        byte[] passwordHash,
        byte[] passwordSalt,
        string displayName,
        string? email,
        string? phoneNumber,
        bool isActive,
        bool isLockedOut,
        int failedAttempts,
        DateTime? lockoutEndUtc,
        DateTime? lastLoginUtc,
        DateTime createdAtUtc,
        DateTime updatedAtUtc)
    {
        return new User(
            id, username, passwordHash, passwordSalt, displayName, email, phoneNumber,
            isActive, isLockedOut, failedAttempts, lockoutEndUtc, lastLoginUtc,
            createdAtUtc, updatedAtUtc);
    }

    #endregion

    public void RecordSuccessfulLogin()
    {
        FailedAttempts = 0;
        LockoutEndUtc = null;
        LastLoginUtc = DateTime.UtcNow;
        UpdatedAtUtc = DateTime.UtcNow;
    }

    public void RecordFailedLogin(int maxAttempts = 5)
    {
        FailedAttempts++;
        UpdatedAtUtc = DateTime.UtcNow;
        if (FailedAttempts >= maxAttempts)
        {
            IsLockedOut = true;
            LockoutEndUtc = DateTime.UtcNow.AddMinutes(30);
        }
    }

    public void ResetLockout()
    {
        IsLockedOut = false;
        FailedAttempts = 0;
        LockoutEndUtc = null;
        UpdatedAtUtc = DateTime.UtcNow;
    }


    public void UpdateProfile(string displayName, string? email, string? phoneNumber)
    {
        if (string.IsNullOrWhiteSpace(displayName))
            throw new DomainException("نام نمایشی الزامی است.");

        DisplayName = displayName.Trim();
        Email = Email.Create(email!.Trim().ToLowerInvariant());
        PhoneNumber = phoneNumber?.Trim();
        UpdatedAtUtc = DateTime.UtcNow;
    }

    public void Deactivate()
    {
        IsActive = false;
        UpdatedAtUtc = DateTime.UtcNow;
    }

    public void Activate()
    {
        IsActive = true;
        ResetLockout();
    }


}
