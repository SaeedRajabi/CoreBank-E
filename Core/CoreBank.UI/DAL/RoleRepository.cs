using Microsoft.Data.SqlClient;

namespace CoreBank.UI.DAL
{
    public class RoleRepository
    {
        private readonly string _connectionString = "Data source = localhost,11433; initial catalog= CoreBank_E_DB ; User = sa ; Password=$@deeasRA2731; TrustServerCertificate=True ; MultipleActiveResultSets=true";
        public RoleRepository()
        {

        }

        public void CreateRole(Role role)
        {
            using (SqlConnection connection = new SqlConnection(_connectionString))
            {
                connection.Open();
                var cmd = new SqlCommand($"INSERT INTO Roles (Name , Description) VALUES(N'{role.Name}', N'{role.Description}');", connection);
                cmd.ExecuteNonQuery();
            }

        }
    }
}
