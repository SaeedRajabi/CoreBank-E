using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Permission : AggregateRoot
{
    private Permission(Guid id, string code, string name, string category, string? description)
        : base(id)
    {
        Code = code;
        Name = name;
        Category = category;
        Description = description;
    }

    public string Code { get; }
    public string Name { get; }
    public string Category { get; }
    public string? Description { get; }

    public static Permission Create(string code, string name, string category, string? description = null)
    {
        if (string.IsNullOrWhiteSpace(code))
            throw new DomainException("کد مجوز الزامی است.");

        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("نام مجوز الزامی است.");

        return new Permission(Guid.NewGuid(), code.Trim(), name.Trim(), category.Trim(), description?.Trim());
    }

    public static Permission Rehydrate(Guid id, string code, string name, string category, string? description)
    {
        return new Permission(id, code, name, category, description);
    }
}
