import React, { useEffect, useState } from "react";
import { Button, message, Steps } from "antd";
import { Input } from "antd";
const { TextArea } = Input;
import GuestService from "../../services/guest";
import { useDispatch, useSelector } from "react-redux";
import { booking } from "../../redux/features/orderSlice";
const NhaSi = ({ TENNS, MAND }) => {
  const dispath = useDispatch();
  const handleOnClick = () => {
    dispath(booking({ mans: MAND }));
    message.success(`Đã chọn nha sĩ ${TENNS}`);
  };
  return (
    <>
      <Button
        onClick={() => handleOnClick()}
        className="p-4 rounded-lg border border-slate-400 h-16"
      >
        <h1>{TENNS}</h1>
      </Button>
    </>
  );
};

const Ca = ({ MACA, NGAY, SOTT }) => {
  function formatDate(inputDate) {
    const date = new Date(inputDate);
    const hours = date.getHours();
    const minutes = date.getMinutes();
    return `${hours}:${minutes} `;
  }
  const [ca, setCa] = useState([]);
  const dispath = useDispatch();
  const handleOnClick = (sott) => {
    message.success(sott);
    dispath(booking({ sott: sott }));
  };
  useEffect(() => {
    GuestService.getAllCa().then((res) => {
      setCa(res);
    });
  }, []);
  const merge = ca.filter((item) => item.MACA === MACA);
  return (
    <>
      <Button
        onClick={() => handleOnClick(SOTT)}
        className="p-4 rounded-lg border border-slate-400 h-16"
      >
        {
          merge?.map((item, index) => (
            <>
              <h1 key={index}>
                {formatDate(item.GIOBATDAU)} - {formatDate(item.GIOKETTHUC)}
              </h1>
              <h1>{NGAY}</h1>
            </>
          ))[0]
        }
      </Button>
    </>
  );
};

const ChonNhaSi = () => {
  const [nhasi, setNhaSi] = useState([]);
  useEffect(() => {
    GuestService.getAllDSNS().then((res) => {
      setNhaSi(res);
    });
  }, []);
  return (
    <>
      <div className="flex justify-center ">
        <div className="grid grid-cols-3 grid-rows-3 gap-4">
          <NhaSi TENNS="Nha Si Bất Kỳ" MAND="" />
          {nhasi?.map((item, index) => (
            <NhaSi key={index} TENNS={item.HOTEN} MAND={item.MANS} />
          ))}
        </div>
      </div>
    </>
  );
};
function convertDate(inputDate) {
  let date = new Date(inputDate);
  let day = date.getDate();
  let month = date.getMonth() + 1;
  let year = date.getFullYear();

  day = day < 10 ? "0" + day : day;
  month = month < 10 ? "0" + month : month;

  return day + "/" + month + "/" + year;
}
const ChonCa = () => {
  const order = useSelector((state) => state.order);
  const [lichRanh, setLichRanh] = useState([]);
  const [lichRanhTheoNgay, setLichRanhTheoNgay] = useState([]);

  useEffect(() => {
    GuestService.lichRanh().then((res) => {
      setLichRanh(res);
    });
    GuestService.xemLRChuaDatTatCaNSTheoNgay().then((res) => {
      console.log(res);
      setLichRanhTheoNgay(res);
    });
  }, []);
  // // console.log("lich ranh cu nha si", new_lichRanh);

  console.log("lich ranh", lichRanh);
  console.log("lich ranh theo ngay", lichRanhTheoNgay);

  const formatlich = lichRanhTheoNgay.map((item, index) => ({
    ...item,
    NGAY: item.NGAY,
    SOTT: item.CA.map((item, index) => index + 1),
    // // MANS:item.CA.NHASI[0].MANS,
    MACA: item.CA[0].MACA,
    // GIOBATDAU:item.CA.GIOBATDAU,
    // GIOKETTHUC:item.CA.GIOKETTHUC,
  }));

  console.log("lich ranh theo ngayssssss", formatlich);
  const new_lichRanh = lichRanh.filter((item) => item.MANS === order.mans);
  return (
    <>
      <div className="flex justify-center">
        <div className=" grid grid-cols-3 grid-rows-3 gap-4">
          {new_lichRanh?.map((item, index) => (
            <Ca
              key={index}
              MACA={item.MACA}
              MANS={item.MANS}
              NGAY={item.NGAY}
              SOTT={item.SOTT}
            />
          ))}
        </div>
      </div>
    </>
  );
};

const LyDoKham = () => {
  const [lydokham, setLyDoKham] = useState("");
  console.log(lydokham);
  const user = useSelector((state) => state.user);
  const dispath = useDispatch();
  const handleOnClick = () => {
    dispath(booking({ lydokham: lydokham, sodt: user.SODT }));
    message.success("Đã chọn lý do khám");
  };

  return (
    <>
      <div className="flex justify-center">
        <div className=" w-[60%]">
          <TextArea
            className=" w-full "
            rows={4}
            value={lydokham}
            onChange={(e) => setLyDoKham(e.target.value)}
          />
          <Button
            onClick={() => handleOnClick()}
            className="p-4 rounded-lg border border-slate-400 h-16"
          >
            <h1>Xác nhận</h1>
          </Button>
        </div>
      </div>
    </>
  );
};

const XacNhan = () => {
  const order = useSelector((state) => state.order);
  const user = useSelector((state) => state.user);
  const dispath = useDispatch();

  return (
    <>
      <div className="flex justify-center flex-col text-neutral-900 ">
        <div className="mx-auto ">
          <h1>Thong tin dat lich</h1>
          <h1>sdt: {order.sodt}</h1>
          <h1>mans: {order.mans}</h1>
          <h1>sott:{order.sott}</h1>
          <h1> lydokham :{order.lydokham}</h1>
        </div>
      </div>
    </>
  );
};
const steps = [
  {
    title: "Chọn Nha Sĩ",
    content: <ChonNhaSi />,
  },
  {
    title: "Chọn Ngày",
    content: <ChonCa />,
  },
  {
    title: "Ly do khám",
    content: <LyDoKham />,
  },
  {
    title: "Xác nhận",
    content: <XacNhan />,
  },
];

const DatLichContainer = () => {
  const [current, setCurrent] = useState(0);
  const next = () => {
    setCurrent(current + 1);
  };
  const prev = () => {
    setCurrent(current - 1);
  };
  const items = steps.map((item) => ({
    key: item.title,
    title: item.title,
    content: item.content,
  }));
  const order = useSelector((state) => state.order);

  const handleBooking = async () => {
    await GuestService.taoLichHen(order).then((res) => {
      console.log(res);
      message.success("Đặt lịch thành công");
    });
  };

  return (
    <>
      <Steps current={current} items={items} />
      <div className=" min-h-[300px] bg-slate-300 mt-4 p-4 rounded-lg border border-slate-400">
        {steps[current].content}
      </div>
      <div className="flex justify-center mt-6">
        {current > 0 && (
          <Button
            style={{
              margin: "0 8px",
            }}
            onClick={() => prev()}
          >
            Previous
          </Button>
        )}
        {current < steps.length - 1 && (
          <Button className="bg-blue-500" type="primary" onClick={() => next()}>
            Next
          </Button>
        )}
        {current === steps.length - 1 && (
          <Button
            className="bg-green-600 ml-2"
            type="primary"
            onClick={() => handleBooking()}
          >
            Done
          </Button>
        )}
      </div>
    </>
  );
};

const DatLichHen = () => {
  return (
    <>
      <div className="">
        <h1 className="mx-auto mb-5">Đặt lịch hẹn</h1>
        <DatLichContainer />
      </div>
    </>
  );
};
export default DatLichHen;
