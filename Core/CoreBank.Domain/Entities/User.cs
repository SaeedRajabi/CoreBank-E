using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;
using System.Security.Cryptography;
using System.Text;

namespace CoreBank.UI.Domain.Entities
{
    public sealed class User : Entity
    {
        private User(
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
            : base(id)
        {
            Username = username;
            PasswordHash = passwordHash;
            PasswordSalt = passwordSalt;
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

        public string Username { get; }
        public byte[] PasswordHash { get; private set; }
        public byte[] PasswordSalt { get; private set; }
        public string DisplayName { get; private set; }
        public string? Email { get; private set; }
        public string? PhoneNumber { get; private set; }
        public bool IsActive { get; private set; }
        public bool IsLockedOut { get; private set; }
        public int FailedAttempts { get; private set; }
        public DateTime? LockoutEndUtc { get; private set; }
        public DateTime? LastLoginUtc { get; private set; }
        public DateTime CreatedAtUtc { get; }
        public DateTime UpdatedAtUtc { get; private set; }

        public static User Create(
            string username,
            string password,
            string displayName,
            string? email = null,
            string? phoneNumber = null)
        {
            if (string.IsNullOrWhiteSpace(username) || username.Length < 3)
                throw new DomainException("نام کاربری باید حداقل ۳ کاراکتر باشد.");

            if (string.IsNullOrWhiteSpace(password) || password.Length < 6)
                throw new DomainException("رمز عبور باید حداقل ۶ کاراکتر باشد.");

            if (string.IsNullOrWhiteSpace(displayName))
                throw new DomainException("نام نمایشی الزامی است.");

            var salt = GenerateSalt();
            var hash = HashPassword(password, salt);

            return new User(
                Guid.NewGuid(),
                username.Trim().ToLowerInvariant(),
                hash,
                salt,
                displayName.Trim(),
                email?.Trim().ToLowerInvariant(),
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

        public bool VerifyPassword(string password)
        {
            if (IsLockedOut)
                throw new DomainException("حساب کاربری قفل شده است.");

            var hash = HashPassword(password, PasswordSalt);
            return CryptographicOperations.FixedTimeEquals(hash, PasswordHash);
        }

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

        public void ChangePassword(string newPassword)
        {
            if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length < 6)
                throw new DomainException("رمز عبور جدید باید حداقل ۶ کاراکتر باشد.");

            PasswordSalt = GenerateSalt();
            PasswordHash = HashPassword(newPassword, PasswordSalt);
            UpdatedAtUtc = DateTime.UtcNow;
        }

        public void UpdateProfile(string displayName, string? email, string? phoneNumber)
        {
            if (string.IsNullOrWhiteSpace(displayName))
                throw new DomainException("نام نمایشی الزامی است.");

            DisplayName = displayName.Trim();
            Email = email?.Trim().ToLowerInvariant();
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

        private static byte[] GenerateSalt()
        {
            var salt = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(salt);
            return salt;
        }

        private static byte[] HashPassword(string password, byte[] salt)
        {
            var combined = Encoding.UTF8.GetBytes(password).Concat(salt).ToArray();
            return SHA256.HashData(combined);
        }
    }
}
