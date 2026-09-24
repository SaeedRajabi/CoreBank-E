using CoreBank.Domain.Common;
using CoreBank.Domain.Exceptions;

namespace CoreBank.Domain.Entities;

public sealed class Role : AggregateRoot
{
    private Role(Guid id, string name, string? description, bool isSystem, DateTime createdAtUtc)
        : base(id)
    {
        Name = name;
        Description = description;
        IsSystem = isSystem;
        CreatedAtUtc = createdAtUtc;
    }

    public string Name { get; }
    public string? Description { get; private set; }
    public bool IsSystem { get; }
    public DateTime CreatedAtUtc { get; }

    public static Role Create(string name, string? description = null, bool isSystem = false)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("نام نقش الزامی است.");

        return new Role(
            Guid.NewGuid(),
            name.Trim(),
            description?.Trim(),
            isSystem,
            DateTime.UtcNow);
    }

    public static Role Rehydrate(Guid id, string name, string? description, bool isSystem, DateTime createdAtUtc)
    {
        return new Role(id, name, description, isSystem, createdAtUtc);
    }

    public void UpdateDescription(string? description)
    {
        Description = description?.Trim();
    }
}
