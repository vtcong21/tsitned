import instance from "./axios.config";
import { message } from "antd";

const Axios = {
  get: async (url) => {
    try {
      const res = await instance.get(url);
      return res.data;
    } catch (err) {
      message.error(err.message);
      console.log(err);
    }
  },
  post: async (url, data) => {
    try {
      const res = await instance.post(url, data);
      if (res.status === 200) {
        message.success("Thành công");
      }
      
      return res.data;
    } catch (err) {
      message.error(err.message);
      console.log(err);
    }
  },
  put: async (url, data) => {
    try {
      const res = await instance.put(url, data);
      if (res.status === 200) {
        message.success("Thành công");
      }
      return res.data;
    } catch (err) {
      message.error(err.message);
      console.log(err);
    }
  },
  patch: async (url, data) => {
    try {
      const res = await instance.patch(url, data);
      if (res.status === 200) {
        message.success("Thành công");
      }
      return res.data;
    } catch (err) {
      message.error(err.message);
      console.log(err);
    }
  },

  delete: async (url) => {
    try {
      const res = await instance.delete(url);
      if (res.status === 200) {
        message.success("Thành công");
      }
      return res.data;
    } catch (err) {
      message.error(err.message);
      console.log(err);
    }
  },
};
export default Axios;