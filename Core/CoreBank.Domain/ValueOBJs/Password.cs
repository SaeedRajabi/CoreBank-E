using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;
using System.Collections;
using System.Security.Cryptography;
using System.Text;

namespace CoreBank.Domain.ValueOBJs;

public class Password : BaseValueOBJs<Password>
{
    #region Constants
    private const int SaltSize = 64;
    #endregion

    #region Properties

    public string HashedPassword { get; private set; }
    public string Salt { get; private set; }

    #endregion

    #region CTORs

    private Password(string hashPassword, string salt)
    {
        HashedPassword = hashPassword;
        Salt = salt;
    }
    #endregion

    #region Factories

    public static Password Create(string plainPassword)
    {
        if (string.IsNullOrWhiteSpace(plainPassword) || plainPassword.Length < 6)
            throw new DomainException("رمز عبور باید حداقل ۶ کاراکتر باشد.");
        var saltResult = GenerateSalt();
        var hash = HashPassword(plainPassword, saltResult);
        return new Password(Convert.ToBase64String(hash), Convert.ToBase64String(saltResult));
    }

    #endregion

    #region Password Hashed

    private static byte[] GenerateSalt()
    {
        var salt = new byte[SaltSize];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(salt);
        return salt;
    }

    private static byte[] HashPassword(string password, byte[] salt)
    {
        var combined = Encoding.UTF8.GetBytes(password).Concat(salt).ToArray();
        return SHA256.HashData(combined);
    }

    public bool Verify(string plainPassword)
    {
        byte[] salt = Convert.FromBase64String(Salt);
        byte[] hash = HashPassword(plainPassword, salt);

        return StructuralComparisons
            .StructuralEqualityComparer
            .Equals(Convert.FromBase64String(HashedPassword), hash);
    }

    public string ChangePassword(string newPassword)
    {
        byte[] saltValueResult = GenerateSalt();
        byte[] passHashed = HashPassword(newPassword, saltValueResult);
        var pass = new Password(Convert.ToBase64String(passHashed), Convert.ToBase64String(saltValueResult));
        return pass.ToString();
    }
    #endregion

    #region Class Methods Override 
    public override string ToString() => HashedPassword;
    #endregion

    #region Override Methods In Parent Class
    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return HashedPassword;
        yield return Salt;
    }
    #endregion
}
