using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Contracts
{
    public class Order
    {
        public required string Id { get; set; }
        public int Amount { get; set; }
        public required string ArticleNumber { get; set; }
        public required Customer Customer { get; set; }
    }
}
