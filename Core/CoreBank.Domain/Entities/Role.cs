namespace CoreBank.UI.Domain.Entities
{
    public class Role
    {
        public string Name { get; private set; }
        public string Description { get; private set; }

        public Role(string name, string description)
        {
            Name = name;
            Description = description;
        }
    }
}
