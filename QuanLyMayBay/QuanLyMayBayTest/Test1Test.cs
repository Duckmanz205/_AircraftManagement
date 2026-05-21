using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium.Support.UI; // Thêm thư viện này để dùng WebDriverWait

namespace QuanLyMayBayTest
{
    [TestClass]
    public class Test1Test
    {
        private IWebDriver driver;
        public IDictionary<string, object> vars { get; private set; }
        private IJavaScriptExecutor js;

        [TestInitialize]
        public void SetUp()
        {
            driver = new ChromeDriver();
            js = (IJavaScriptExecutor)driver;
            vars = new Dictionary<string, object>();
        }

        [TestCleanup]
        public void TearDown()
        {
            if (driver != null)
            {
                driver.Quit(); // Lệnh này sẽ tự động đóng mọi cửa sổ nên không cần driver.Close() ở dưới nữa
            }
        }

        [TestMethod]
        public void test1()
        {
            driver.Navigate().GoToUrl("https://localhost:44373/");
            driver.Manage().Window.Size = new System.Drawing.Size(1296, 688);

            driver.FindElement(By.CssSelector(".bg-blue-600")).Click();
            driver.FindElement(By.Id("email")).Click();
            driver.FindElement(By.Id("email")).SendKeys("khoa@gmail.com");
            driver.FindElement(By.Id("password")).Click();
            driver.FindElement(By.Id("password")).SendKeys("123456");
            driver.FindElement(By.CssSelector(".hover\\3A bg-blue-700")).Click();

            // SỬ DỤNG EXPLICIT WAIT
            // Chờ tối đa 10 giây cho đến khi dòng chữ chào mừng xuất hiện sau khi đăng nhập
            WebDriverWait wait = new WebDriverWait(driver, TimeSpan.FromSeconds(10));
            IWebElement welcomeMessage = wait.Until(d => d.FindElement(By.CssSelector(".text-blue-800")));

            // Kiểm tra nội dung Text (Cú pháp của MSTest)
            Assert.AreEqual("Chào mừng trở lại, Nguyễn Minh Khoa!", welcomeMessage.Text);
        }
    }
}