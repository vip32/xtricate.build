using System.Configuration;
using System.Web.Mvc;

namespace demo.webapp.Controllers
{
    public class HomeController : Controller
    {
        private InstancesRepository _repository;

        public HomeController()
        {
            _repository = new InstancesRepository(
                new DemoDatabase("demodb"));
        }

        public ActionResult Index()
        {
            ViewBag.Message = "Welcome to ASP.NET MVC!";
            ViewBag.RepositoryValue = _repository.Get("id1").Value;
            ViewBag.AppSettingValue = ConfigurationManager.AppSettings["appsetting1"];
            return View();
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
