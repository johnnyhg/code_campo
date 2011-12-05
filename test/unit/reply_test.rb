require 'test_helper'

class ReplyTest < ActiveSupport::TestCase
  test "should set number_id before_create" do
    reply = Factory.build :reply
    assert_nil reply.number_id
    reply.save
    assert_equal 1, reply.number_id
    assert_equal 2, Factory(:reply).number_id

    assert_equal reply, Reply.number(reply.number_id)
  end

  test "should update topic's actived_at column" do
    topic = Factory :topic
    topic.update_attribute :actived_at, 1.hour.ago
    old_time = topic.actived_at
    Factory :reply, :topic => topic
    assert_not_equal old_time.to_i, topic.actived_at.to_i
  end

  test "should mark replier to topic" do
    topic = Factory :topic
    user = Factory :user
    Factory :reply, :topic => topic, :user => user
    
    assert topic.reload.replied_by?(user)
  end

  test "should inc topic's replies_count column" do
    topic = Factory :topic
    assert_equal 0, topic.replies_count
    assert_difference "topic.reload.replies_count" do
      Factory :reply, :topic => topic
    end
  end

  test "should reset topic's actived_at" do
    topic = Factory :topic
    reply = Factory :reply, :topic => topic
    reply_other = Factory :reply, :topic => topic, :created_at => 1.minutes.from_now
    reply_other.destroy
    assert_equal reply.created_at.to_i, topic.actived_at.to_i
  end

  test "should set topic's last_reply_user" do
    topic = Factory :topic
    reply = Factory :reply, :topic => topic
    assert_equal reply.user, topic.last_reply_user
  end

  test "should reset topic's last_reply_user" do
    topic = Factory :topic
    reply = Factory :reply, :topic => topic
    reply_other = Factory :reply, :topic => topic
    reply_other.destroy
    assert_equal reply.user, topic.last_reply_user
    reply.destroy
    assert_nil topic.last_reply_user
  end

  test "should not send mention notfication to topic user" do
    topic = Factory :topic
    assert_no_difference "topic.user.notifications.where(:_type => 'Notification::Mention').count" do
      Factory :reply, :topic => topic, :content => "@#{topic.user.name}"
    end
  end

  test "should send topic reply notification" do
    topic = Factory :topic
    assert_difference "topic.user.notifications.unread.count" do
      Factory :reply, :topic => topic
    end
    assert_no_difference "topic.user.notifications.unread.count" do
      Factory :reply, :topic => topic, :user => topic.user
    end
  end
end
