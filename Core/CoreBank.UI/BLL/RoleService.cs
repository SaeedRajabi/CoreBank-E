using CoreBank.UI.DAL;

namespace CoreBank.UI.BLL
{
    public class RoleService
    {
        private readonly RoleRepository _repository;
        public RoleService(RoleRepository repository)
        {
            _repository = repository;
        }
        public RoleService()
        {

        }

        public void CreateRole(Role role)
        {
            if (string.IsNullOrEmpty(role.Name))
                throw new ArgumentNullException("Role Name is not empty.");
            if (string.IsNullOrEmpty(role.Description))
                throw new ArgumentNullException("description is not empty.");

            _repository.CreateRole(role);
        }

    }
}
