#include "cpp_greeter/greeter.hpp"

namespace cpp_greeter
{
std::string make_greeting(int count)
{
  return "hello-from-cpp-greeter " + std::to_string(count);
}
}  // namespace cpp_greeter
