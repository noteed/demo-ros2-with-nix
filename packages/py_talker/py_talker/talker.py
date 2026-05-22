import rclpy
from rclpy.node import Node
from std_msgs.msg import String


class Talker(Node):
    def __init__(self):
        super().__init__("py_talker")
        self.publisher = self.create_publisher(String, "demo_chatter", 10)
        self.count = 0
        self.create_timer(0.5, self.tick)

    def tick(self):
        msg = String(data=f"hello-from-py-talker {self.count}")
        self.publisher.publish(msg)
        self.get_logger().info(f"publishing: {msg.data}")
        self.count += 1


def main():
    rclpy.init()
    node = Talker()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
