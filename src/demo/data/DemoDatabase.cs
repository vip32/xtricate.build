using System.Data.Entity;

namespace demo
{
    public class DemoDatabase : DbContext
    {
        public DemoDatabase(string connection) : base(connection)
        {
        }
         
        public DbSet<Instance> Instances { get; set; }
    }
}
