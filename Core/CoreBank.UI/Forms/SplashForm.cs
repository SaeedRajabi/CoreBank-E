using CoreBank.UI.BLL;

namespace CoreBank.UI.Forms
{
    public partial class SplashForm : Form
    {
        public SplashForm()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {

            Role role = new Role(textBox1.Text, textBox2.Text);
            RoleService roleService = new RoleService();
            roleService.CreateRole(role);
        }
    }
}
