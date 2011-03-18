using System;
using System.Linq;

namespace demo
{
    public class InstancesRepository
    {
        private readonly DemoDatabase _database;

        public InstancesRepository(DemoDatabase database)
        {
            _database = database;
        }

        public Instance Get(string id)
        {
            return _database.Instances.FirstOrDefault(x => x.InstanceId.Equals(id, StringComparison.InvariantCultureIgnoreCase));
        }

        public void Add(Instance instance)
        {
            _database.Instances.Add(instance);
            _database.SaveChanges();
        }
    }
}
