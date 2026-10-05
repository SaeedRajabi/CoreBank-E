using CoreBank.Domain.Entities;

namespace CoreBank.ApplicationService.Contracts;

public interface IUserRepository
{
    User GetUserByUsername(string username);
    User GetUserById(Guid userId);

    IReadOnlyList<User> GetAllUsers();


    void AddUser(User user);
    void UpdateUser(User user);
    int UserCount();

    IReadOnlyList<string> GetUserRoles(Guid userId);
    IReadOnlyList<string> GetUserPermissions(Guid userId);

    void AssignRole(Guid userId, Guid roleId);

    void RemoveRole(Guid userId, Guid roleId);

    bool UserHasRole(Guid userId, string roleName);

    void AddLoginHistory(Guid userId, string userName, bool isSuccess, string? failureReason);

    //IReadOnlyList<LoginHistoryDto> GetLoginHistory(Guid? userId = null , int limit = 50);

}
