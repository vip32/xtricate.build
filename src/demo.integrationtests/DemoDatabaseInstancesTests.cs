using System;
using NUnit.Framework;

namespace demo.integrationtests
{
    [TestFixture]
    public class DemoDatabaseInstancesTests
    {
        private InstancesRepository _repository;

        [TestFixtureSetUp]
        public virtual void FixtureSetup()
        {
            _repository = new InstancesRepository(
                new DemoDatabase("demodb"));
        }

        [Test]
        public void Can_Get_Instance_By_Id()
        {
            var val = _repository.Get("id1");
            Assert.That(val, Is.Not.Null);
            Assert.That(val.Value, Is.EqualTo("local1"));
        }

        [Test]
        public void Can_Add_New_Instance()
        {
            var id = Guid.NewGuid().ToString();
            _repository.Add(new Instance() { InstanceId = id, Value = id}) ;

            var result = _repository.Get(id);
            Assert.That(result, Is.Not.Null);
            Assert.That(result.InstanceId, Is.EqualTo(id));
            Assert.That(result.Value, Is.EqualTo(id));
        }
    }

    
}
