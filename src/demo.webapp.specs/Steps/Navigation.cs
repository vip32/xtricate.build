using System.Configuration;
using TechTalk.SpecFlow;
using NUnit.Framework;
using WatiN.Core;

namespace demo.webapp.specs
{
    [Binding]
    public class Navigation
    {
        [When(@"I navigate to (.*)")]
        public void WhenINavigateTo(string relativeUrl)
        {
            var url = string.Format("{0}/{1}", ConfigurationManager.AppSettings["rooturl"], relativeUrl);
            WebBrowser.Current.GoTo(url);
        }

        [Then(@"I should be on the home page")]
        public void ThenIShouldBeOnTheHomePage()
        {
            Assert.That(WebBrowser.Current.Title, Is.EqualTo("xtricate.build demo site"));
        }

        [Then(@"I should see the text equal to appsetting ""(.*)""")]
        public void ThenIShouldSeeTheAppsetting(string appsetting)
        {
            var text = ConfigurationManager.AppSettings[appsetting];
            var found = WebBrowser.Current.Text.Contains(text);
            Assert.That(found, Is.EqualTo(true));
        }

        [Then(@"I should see the text equal to ""(.*)""")]
        public void ThenIShouldSeeTheText(string text)
        {
            var found = WebBrowser.Current.Html.Contains(text);
            Assert.That(found, Is.EqualTo(true));
        }
    }
}
