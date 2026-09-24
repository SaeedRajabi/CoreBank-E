namespace CoreBank.Domain.Exceptions;

public class InvalidValueObjectStateException : Exception
{
    public InvalidValueObjectStateException(string message) : base(message) { }
}
