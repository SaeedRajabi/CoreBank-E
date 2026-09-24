using CoreBank.Domain.Common;
using CoreBank.Domain.Enums;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Customer : AggregateRoot
{
    private Customer(
        Guid id,
        string customerNumber,
        CustomerType type,
        string displayName,
        string? nationalId,
        string? companyNationalId,
        DateTime? birthDate,
        DateTime? registrationDate,
        string? phoneNumber,
        string? address,
        string? postalCode,
        CustomerStatus status = CustomerStatus.Active,
        RiskLevel riskLevel = RiskLevel.Low,
        DateTime? createdAtUtc = null,
        DateTime? updatedAtUtc = null)
        : base(id)
    {
        CustomerNumber = customerNumber;
        Type = type;
        DisplayName = displayName;
        NationalId = nationalId;
        CompanyNationalId = companyNationalId;
        BirthDate = birthDate;
        RegistrationDate = registrationDate;
        PhoneNumber = phoneNumber;
        Address = address;
        PostalCode = postalCode;
        Status = status;
        RiskLevel = riskLevel;
        CreatedAtUtc = createdAtUtc ?? DateTime.UtcNow;
        UpdatedAtUtc = updatedAtUtc ?? CreatedAtUtc;
    }

    public string CustomerNumber { get; }
    public CustomerType Type { get; }
    public string DisplayName { get; private set; }
    public string? NationalId { get; }
    public string? CompanyNationalId { get; }
    public DateTime? BirthDate { get; }
    public DateTime? RegistrationDate { get; }
    public string? PhoneNumber { get; private set; }
    public string? Address { get; private set; }
    public string? PostalCode { get; private set; }
    public CustomerStatus Status { get; private set; }
    public RiskLevel RiskLevel { get; private set; }
    public DateTime CreatedAtUtc { get; }
    public DateTime UpdatedAtUtc { get; private set; }

    public static Customer CreateIndividual(
        string customerNumber,
        string nationalId,
        string firstName,
        string lastName,
        DateTime birthDate,
        string? phoneNumber,
        string? address,
        string? postalCode)
    {
        if (string.IsNullOrWhiteSpace(nationalId) || nationalId.Trim().Length != 10)
        {
            throw new DomainException("کد ملی باید ۱۰ رقم باشد.");
        }

        var displayName = $"{firstName.Trim()} {lastName.Trim()}".Trim();
        if (displayName.Length < 3)
        {
            throw new DomainException("نام و نام خانوادگی الزامی است.");
        }

        return new Customer(
            Guid.NewGuid(),
            customerNumber,
            CustomerType.Individual,
            displayName,
            nationalId.Trim(),
            null,
            birthDate,
            null,
            phoneNumber,
            address,
            postalCode);
    }

    public static Customer CreateLegal(
        string customerNumber,
        string companyNationalId,
        string companyName,
        DateTime registrationDate,
        string? phoneNumber,
        string? address,
        string? postalCode)
    {
        if (string.IsNullOrWhiteSpace(companyNationalId))
        {
            throw new DomainException("شناسه ملی شرکت الزامی است.");
        }

        if (string.IsNullOrWhiteSpace(companyName))
        {
            throw new DomainException("نام شرکت الزامی است.");
        }

        return new Customer(
            Guid.NewGuid(),
            customerNumber,
            CustomerType.Legal,
            companyName.Trim(),
            null,
            companyNationalId.Trim(),
            null,
            registrationDate,
            phoneNumber,
            address,
            postalCode);
    }

    /// <summary>
    /// Recreates a customer from persistence without generating a new identity or
    /// resetting its lifecycle fields.
    /// </summary>
    public static Customer Rehydrate(
        Guid id,
        string customerNumber,
        CustomerType type,
        string displayName,
        string? nationalId,
        string? companyNationalId,
        DateTime? birthDate,
        DateTime? registrationDate,
        string? phoneNumber,
        string? address,
        string? postalCode,
        CustomerStatus status,
        RiskLevel riskLevel,
        DateTime createdAtUtc,
        DateTime updatedAtUtc)
    {
        if (id == Guid.Empty)
        {
            throw new DomainException("شناسه مشتری معتبر نیست.");
        }

        if (string.IsNullOrWhiteSpace(customerNumber))
        {
            throw new DomainException("شماره مشتری الزامی است.");
        }

        if (string.IsNullOrWhiteSpace(displayName))
        {
            throw new DomainException("نام مشتری الزامی است.");
        }

        return new Customer(
            id,
            customerNumber,
            type,
            displayName,
            nationalId,
            companyNationalId,
            birthDate,
            registrationDate,
            phoneNumber,
            address,
            postalCode,
            status,
            riskLevel,
            createdAtUtc,
            updatedAtUtc);
    }

    public void UpdateContact(string? phoneNumber, string? address, string? postalCode)
    {
        PhoneNumber = phoneNumber;
        Address = address;
        PostalCode = postalCode;
        UpdatedAtUtc = DateTime.UtcNow;
    }

    public void ChangeRisk(RiskLevel riskLevel)
    {
        RiskLevel = riskLevel;
        UpdatedAtUtc = DateTime.UtcNow;
    }

    public void ChangeStatus(CustomerStatus status)
    {
        Status = status;
        UpdatedAtUtc = DateTime.UtcNow;
    }
}
