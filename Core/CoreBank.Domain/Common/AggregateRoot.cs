namespace CoreBank.Domain.Common;

public class AggregateRoot : Entity, IAggregateRoot
{
    protected AggregateRoot(Guid id) : base(id) { }
}
