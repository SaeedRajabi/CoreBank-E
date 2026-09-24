namespace CoreBank.Domain.Common;

public abstract class BaseValueOBJs<TValueOBJ> : IEquatable<TValueOBJ> where TValueOBJ : BaseValueOBJs<TValueOBJ>
{
    #region Impliment IEquatable Required Method
    public bool Equals(TValueOBJ? other) => this == other!;
    #endregion

    #region Class Methods Override 
    public override bool Equals(object? obj)
    {
        if (obj is not TValueOBJ otherObject) return false;
        return GetEqualityComponents().SequenceEqual(otherObject.GetEqualityComponents());

    }

    public override int GetHashCode()
    {
        return GetEqualityComponents()
            .Select(x => x != null ? x.GetHashCode() : 0)
            .Aggregate((x, y) => x ^ y);
    }
    #endregion

    #region Defind Abstraction Method Without Impliment
    protected abstract IEnumerable<object> GetEqualityComponents();
    #endregion

    #region Operator Override Methods
    public static bool operator ==(BaseValueOBJs<TValueOBJ> Right, BaseValueOBJs<TValueOBJ> Left)
    {
        if (Right is null && Left is null)
            return true;
        if (Right is null || Left is null)
            return false;
        return Right.Equals(Left);
    }
    public static bool operator !=(BaseValueOBJs<TValueOBJ> Right, BaseValueOBJs<TValueOBJ> Left) => !(Right == Left);
    #endregion
}
