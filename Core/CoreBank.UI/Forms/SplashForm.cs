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


        }

        private void SplashForm_Load(object sender, EventArgs e)
        {
            var generator = GetFibonacciSequnece(1000);
            foreach (var item in generator)
            {
                Console.Write(item + " , ");
            }
        }

        public IEnumerable<long> GetFibonacciSequnece(int count)
        {
            long a = 0, b = 1;
            for (int i = 0; i < count; i++)
            {
                yield return a;
                long temp = a;
                a = b;
                b = temp + b;
            }
        }
    }
}
