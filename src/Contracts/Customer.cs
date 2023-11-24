using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Contracts
{
    public class Customer
    {
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
    }
}
