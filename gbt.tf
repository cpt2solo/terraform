#
# Simple configuration with two web nodes and one load balancer
# Use existing network and security groups for simplicity
#

#resource "openstack_networking_network_v2" "network_3054" {
#  name = "network_3054"
#}

#
# web node 1
#
resource "openstack_compute_instance_v2" "gbt-01" {
  name      = "gbt-01"
  availability_zone    = "MS1"
  image_id  = "4525415d-df00-4f32-a434-b8469953fe3e"
  flavor_id = "19b38715-48cd-495b-9391-4c4e9d424518"
  key_pair  = "gbt-01-c0d6Fkxz"
  security_groups = ["default","ssh+www"]
  config_drive = "true"
  user_data = "${file("bootstrapweb.sh")}"

  network {
    name = "network_3054"
  }
}

#
# web node 2
#
resource "openstack_compute_instance_v2" "gbt-02" {
  name      = "gbt-02"
  availability_zone    = "DP1"
  image_id  = "4525415d-df00-4f32-a434-b8469953fe3e"
  flavor_id = "19b38715-48cd-495b-9391-4c4e9d424518"
  key_pair  = "gbt-01-c0d6Fkxz"
  security_groups = ["default","ssh+www"]
  config_drive = "true"
  user_data = "${file("bootstrapweb.sh")}"

  network {
    name = "network_3054"
  }
}

# 
# load balancer
#
resource "openstack_lb_loadbalancer_v2" "gbt-lb1" {
  name = "gbt-lb1"
  vip_network_id = "${openstack_compute_instance_v2.gbt-01.network[0].uuid}"
}

resource "openstack_lb_listener_v2" "listener_1" {
  name            = "listener_1"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.gbt-lb1.id}"
}

resource "openstack_lb_pool_v2" "pool_1" {
  name        = "pool_1"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.listener_1.id}"
}

resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id     = "${openstack_lb_pool_v2.pool_1.id}"
  type        = "HTTP"
  url_path    = "/"
  delay       = 5
  timeout     = 10
  max_retries = 4
}

resource "openstack_lb_member_v2" "member_1" {
  pool_id       = "${openstack_lb_pool_v2.pool_1.id}"
  address       = "${openstack_compute_instance_v2.gbt-01.network[0].fixed_ip_v4}"
  protocol_port = 80
}

resource "openstack_lb_member_v2" "member_2" {
  pool_id       = "${openstack_lb_pool_v2.pool_1.id}"
  address       = "${openstack_compute_instance_v2.gbt-02.network[0].fixed_ip_v4}"
  protocol_port = 80
}

#
# floating (external) ip
#
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = "ext-net"
}

resource "openstack_networking_floatingip_associate_v2" "floatip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.floatip_1.address}"
  port_id = "${openstack_lb_loadbalancer_v2.gbt-lb1.vip_port_id}"
}
