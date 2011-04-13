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
            ViewBag.Message = "Welcome to the xtricate.build demo site";
            var val = _repository.Get("id1");
            ViewBag.RepositoryValue = val != null ? val.Value : "NOTFOUND";
            ViewBag.WorldtimeServerUrl = ConfigurationManager.AppSettings["worldtimeserverurl"];
            ViewBag.Setting1Value = ConfigurationManager.AppSettings["setting1"];
            ViewBag.Setting2Value = ConfigurationManager.AppSettings["setting2"];
            ViewBag.Setting3Value = ConfigurationManager.AppSettings["setting3"];
            return View();
        }

        public ActionResult About()
        {
            return View();
        }
    }
}
