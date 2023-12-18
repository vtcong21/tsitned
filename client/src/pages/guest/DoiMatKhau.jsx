import React, { useState } from "react";
import { Form, Input } from "antd";
import DentistService from "../../services/dentist";
import { useSelector } from "react-redux";
import { ButtonBlue } from "~/components/button";
const DoiMatKhau = () => {
  const user = useSelector((state) => state.user);
  const { ROLE, HOTEN, PHAI, MANS } = user;
  const [form] = Form.useForm();

  const onFinish = async (values) => {
    const newInfo = {
      mans: MANS,
      matkhaucu: values.matkhaucu,
      matkhaumoi: values.matkhaumoi,
    };
  };
  const onFinishFailed = (errorInfo) => {
    console.log("Failed:", errorInfo);
  };
  return (
    <div className="bg-[#dddddd] w-[800px] h-[500px] rounded-lg p-2 mx-auto">
      <h1 className="text-2xl mb-4">Đổi mật khẩu  </h1>
      <div className="flex flex-col  min-h-[400px]">
        <Form
          name="basic"
          form={form}
          onFinish={onFinish}
          onFinishFailed={onFinishFailed}
          autoComplete="off"
        >
          <Form.Item
            label="Mật Khẩu Cũ"
            name="matkhaucu"
            rules={[
              {
                required: true,
                message: "Vui lòng nhập mật khẩu!",
              },
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item
            label="Mật Khẩu Mới"
            name="matkhaumoi"
            rules={[
              {
                required: true,
                message: "Vui lòng nhập mật khẩu!",
              },
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item
            label="Xác Nhận Mật Khẩu Mới"
            name="xacnhanmatkhaumoi"
            rules={[
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue("matkhaumoi") === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(
                    new Error(
                      "Mật khẩu xác nhận không trùng khớp với mật khẩu mới!"
                    )
                  );
                },
              }),
            ]}
          >
            <Input.Password />
          </Form.Item>
          <Form.Item>
            <ButtonBlue text="Đổi mật khẩu" htmlType="submit" />
          </Form.Item>
        </Form>
      </div>
    </div>
  );
};
export default DoiMatKhau;
