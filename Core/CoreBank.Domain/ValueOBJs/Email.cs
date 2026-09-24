using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;
using System.Text.RegularExpressions;

namespace CoreBank.Domain.ValueOBJs;

public class Email : BaseValueOBJs<Email>
{
    #region Factories
    public static Email Create(string value) => new Email(value);

    #endregion

    #region Properties
    public string Value { get; private set; }
    #endregion

    #region CTORs
    private Email(string value)
    {
        Validation(value);
        Value = value;
    }
    #endregion

    #region Check Validation Method
    private void Validation(string value)
    {
        string EmailPatternCheck = @"\A[A-Za-z][A-Za-z0-9.ـ]*@(gmail|yahoo)\.com\z";
        Regex regex = new Regex(EmailPatternCheck);
        if (string.IsNullOrEmpty(value))
            throw new InvalidValueObjectStateException("ValidationErrorIsRequired");
        if (value.Length > 120)
            throw new InvalidValueObjectStateException("ValidationErrorStringLength");
        if (!regex.IsMatch(value))
            throw new InvalidValueObjectStateException("ValidationErrorIsEnglishCharecterOnly");
    }
    #endregion

    #region Class Methods Override 
    public override string ToString() => Value;
    #endregion

    #region Override Methods In Parent Class
    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Value;
    }
    #endregion

    #region Casting Excplicit And Implicit Operator Override
    public static explicit operator string(Email title) => title.Value.ToString(); // (string)Email 
    public static implicit operator Email(string value) => new Email(value);
    #endregion
}
