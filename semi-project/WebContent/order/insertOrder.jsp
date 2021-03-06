<%@page import="java.util.Arrays"%>
<%@page import="semi.dao.BucketDao"%>
<%@page import="semi.vo.PointHistory"%>
<%@page import="semi.dao.PointHistoryDao"%>
<%@page import="semi.dao.ProductDao"%>
<%@page import="semi.vo.Item"%>
<%@page import="semi.dao.ItemDao"%>
<%@page import="semi.vo.User"%>
<%@page import="semi.dao.UserDao"%>
<%@page import="semi.vo.OrderProduct"%>
<%@page import="semi.vo.Order"%>
<%@page import="semi.dao.OrderDao"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%

	//System.out.println("insertOrder.jsp 페이지");
	
	request.setCharacterEncoding("utf-8");
	String[] itemNos = request.getParameterValues("itemNo");
	String[] amounts = request.getParameterValues("amount");
	String[] prices = request.getParameterValues("price");
	
	// 파라미터 전달 테스트
	for (int i = 0; i < itemNos.length; i++) {
		System.out.println(itemNos[i]);
		System.out.println(amounts[i]);
		System.out.println(prices[i]);
	}
	
	int totalPrice = Integer.parseInt(request.getParameter("totalPrice"));
	int point = Integer.parseInt(request.getParameter("point"));
	
	// 파라미터 전달테스트
	System.out.println("totalPrice: "+totalPrice);
	System.out.println("point: "+point);
	
	OrderDao orderDao = new OrderDao();
	int orderNo = orderDao.getSeq();
	String userId = (String) session.getAttribute("아이디");
	//System.out.println("orderNo: "+orderNo);
	
	Order order = new Order();
	order.setOrderNo(orderNo);
	order.setUserId(userId);
	order.setTotalPrice(totalPrice);
	order.setPoint(point);
	order.setPrice(totalPrice-point);
	orderDao.insertOrder(order);
	
	ItemDao itemDao = new ItemDao();
	ProductDao productDao = new ProductDao();
	// 구매한 아이템의 상품 포인트 합산
	int getPoint = 0;
	
	// 구매 아이템 목록 저장
	for (int i = 0; i < itemNos.length; i++) {
		OrderProduct orderItem = new OrderProduct();
		int itemNo = Integer.parseInt(itemNos[i]);
		int amount = Integer.parseInt(amounts[i]);
		orderItem.setOrderNo(orderNo);
		orderItem.setItemNo(itemNo);
		orderItem.setOrderedAmount(amount);
		orderItem.setOrderedPrice(Integer.parseInt(prices[i]));
		orderDao.insertOrderProduct(orderItem);
		
		// 재고에서 빼기
		Item item = itemDao.getItemByNo(itemNo);
		item.setStock(item.getStock()-amount);
		itemDao.updateStock(item);
		
		// 각 아이템별 포인트 합산
		int itemPoint = productDao.getProductByNo(item.getProductNo()).getPoint();
		getPoint += itemPoint*amount;
	}
	
	// 유저 사용포인트 차감
	UserDao userDao = new UserDao();
	User user = userDao.getUserById(userId);
	//user.setPoint(user.getPoint()-point+getPoint);	//기존포인트-사용포인트+상품구매로 얻은 포인트
	user.setPoint(user.getPoint()-point);	//기존포인트-사용포인트
	userDao.updatePoint(user);
	
	// 유저 포인트 사용내역 추가
	PointHistoryDao pointHistoryDao = new PointHistoryDao();
	PointHistory history = new PointHistory();
	history.setUserId(userId);
	if (point != 0) {

		history.setOrderNo(pointHistoryDao.getLastSeqNumOfOrderNo());

		history.setReason("사용");
		history.setChange(point);
		pointHistoryDao.insertHistory(history);
		System.out.println("사용: " + point);
	}
	
	//history.setReason("적립");
	//history.setChange(getPoint);
	//pointHistoryDao.insertHistory(history);
	//System.out.println("적립: " + getPoint);
	
	/*
	// 유저 총 구매한 금액 업데이트
	//user.setTotalOrderPrice(totalOrderPrice)
	int updateOrderPrice = user.getTotalOrderPrice()+order.getPrice();
	user.setTotalOrderPrice(updateOrderPrice);
	userDao.updateTotalOrderPrice(user);
	*/
	
	// 장바구니 삭제
	
	String loginedId = (String) session.getAttribute("아이디");
	
	//System.out.println("loginedId: " + loginedId);
	
	String[] buckets = request.getParameterValues("bucketnos");
	
	if (buckets == null) {
		response.sendRedirect("success.jsp?orderNo="+order.getOrderNo());	
	} else {
		BucketDao bucketDao = new BucketDao();
		bucketDao.deleteBucketbyBucketNos(loginedId , Arrays.stream(buckets).mapToInt(Integer::parseInt).toArray());
		response.sendRedirect("success.jsp?orderNo="+order.getOrderNo());	
	}
		
	// 구매완료
%>

