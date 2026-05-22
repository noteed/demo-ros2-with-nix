#ifndef CPP_GREETER__GREETER_HPP_
#define CPP_GREETER__GREETER_HPP_

#include <string>

namespace cpp_greeter
{
// Builds a greeting string. Exported for downstream packages that link this
// library and include this header.
std::string make_greeting(int count);
}  // namespace cpp_greeter

#endif  // CPP_GREETER__GREETER_HPP_
