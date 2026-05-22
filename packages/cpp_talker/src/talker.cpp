#include <chrono>
#include <memory>

#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/string.hpp"

#include "cpp_greeter/greeter.hpp"

using namespace std::chrono_literals;

class Talker : public rclcpp::Node
{
public:
  Talker()
  : Node("cpp_talker"), count_(0)
  {
    publisher_ = this->create_publisher<std_msgs::msg::String>("demo_chatter", 10);
    timer_ = this->create_wall_timer(
      500ms,
      [this]() {
        std_msgs::msg::String msg;
        msg.data = cpp_greeter::make_greeting(count_++);
        RCLCPP_INFO(this->get_logger(), "publishing: %s", msg.data.c_str());
        publisher_->publish(msg);
      });
  }

private:
  rclcpp::TimerBase::SharedPtr timer_;
  rclcpp::Publisher<std_msgs::msg::String>::SharedPtr publisher_;
  int count_;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<Talker>());
  rclcpp::shutdown();
  return 0;
}
