using CoreBank.ApplicationService.Contracts;
using CoreBank.Domain.Entities;

namespace CoreBank.Infrastructure.Repositories;

public class SQL_UserRepository : IAuthRepository
{
    public void AddLoginHistory(Guid userId, string userName, bool isSuccess, string? failureReason)
    {
        throw new NotImplementedException();
    }

    public void AddUser(User user)
    {
        throw new NotImplementedException();
    }

    public void AssignRole(Guid userId, Guid roleId)
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<User> GetAllUsers()
    {
        throw new NotImplementedException();
    }

    public User GetUserById(Guid userId)
    {
        throw new NotImplementedException();
    }

    public User GetUserByUsername(string username)
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<string> GetUserPermissions(Guid userId)
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<string> GetUserRoles(Guid userId)
    {
        throw new NotImplementedException();
    }

    public void RemoveRole(Guid userId, Guid roleId)
    {
        throw new NotImplementedException();
    }

    public void UpdateUser(User user)
    {
        throw new NotImplementedException();
    }

    public int UserCount()
    {
        throw new NotImplementedException();
    }

    public bool UserHasRole(Guid userId, string roleName)
    {
        throw new NotImplementedException();
    }
}
