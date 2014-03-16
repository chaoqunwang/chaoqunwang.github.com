---
layout: post
title: "常用排序算法的java实现"
date: 2010-08-08 21:09:09 -0800
comments: true
categories: tech java 算法 代码
keywords: java 算法 代码
tags: java 算法
description: 常用排序算法的java实现
---
分类 - 插入排序：直接插入排序，希尔排序
- 交换排序：冒泡排序，快速排序
- 选择排序：简单选择排序，堆排序
- 归并排序  
时间复杂度：简单排序如插入、冒泡、选择是O(n²)，高级如快速、归并、堆是O(nlgn)  
本类使用枚举存入各算法和接口实现，main方法打印排序后的数组  
```java 
/**
 * 排序算法接口
 */
interface Sort {
    public void sort(int[] data);
}

```
<!--more-->  

```java 
/**
 * 排序算法枚举
 */
enum Sorts {
	INSERT() {
		public void sort(int[] data) {
			new InsertSort().sort(data);
		}
	},
	BUBBLE() {
		public void sort(int[] data) {
			new BubbleSort().sort(data);
		}
	},
	SELECT() {
		public void sort(int[] data) {
			new SelectionSort().sort(data);
		}
	},
	SHELL() {
		public void sort(int[] data) {
			new ShellSort().sort(data);
		}
	},
	QUICK() {
		public void sort(int[] data) {
			new QuickSort().sort(data);
		}
	},
	MERGE() {
		public void sort(int[] data) {
			new MergeSort().sort(data);
		}
	},
	HEAP() {
		public void sort(int[] data) {
			new HeapSort().sort(data);
		}
	};

	public abstract void sort(int[] data);
}
```  

标签：[算法](/blog/categories/suan-fa/)   

```java 
/**
 * 插入排序算法
 */
class InsertSort implements Sort {
	public void sort(int[] data) {
		for (int i = 1; i < data.length; i++) {
			for (int j = i; j > 0 && data[j] < data[j - 1]; j--) {
				SortUtil.swap(data, j, j - 1);
			}
		}
	}
}

/**
 * 冒泡排序算法
 */
class BubbleSort implements Sort {
	public void sort(int[] data) {
		for (int i = 0; i < data.length; i++) {
			for (int j = data.length - 1; j > i; j--) {
				if (data[j] < data[j - 1]) {
					SortUtil.swap(data, j, j - 1);
				}
			}
		}
	}

}

/**
 * 选择排序算法
 */
class SelectionSort implements Sort {
	public void sort(int[] data) {
		for (int i = 0; i < data.length; i++) {
			int lowIndex = i;
			for (int j = data.length - 1; j > i; j--) {
				if (data[j] < data[lowIndex]) {
					lowIndex = j;
				}
			}
			SortUtil.swap(data, i, lowIndex);
		}
	}

}

/**
 * 希尔排序算法
 */
class ShellSort implements Sort {
	public void sort(int[] data) {
		for (int i = data.length / 2; i > 2; i /= 2) {
			for (int j = 0; j < i; j++) {
				insertSort(data, j, i);
			}
		}
		insertSort(data, 0, 1);
	}

	private void insertSort(int[] data, int start, int inc) {
		for (int i = start + inc; i < data.length; i += inc) {
			for (int j = i; j >= inc && data[j] < data[j - inc]; j -= inc) {
				SortUtil.swap(data, j, j - inc);
			}
		}
	}

}

/**
 * 快速排序算法
 */
class QuickSort implements Sort {
	public void sort(int[] data) {
		quickSort(data, 0, data.length - 1);
	}

	private void quickSort(int[] data, int left, int right) {
		if (left >= right) { return; }

		int pivot = partition(data, left, right);
		quickSort(data, left, pivot);// 对左半段排序
		quickSort(data, pivot + 1, right);// 对右半段排序

	}

	private int partition(int[] data, int left, int right) {
		int pivot = data[left];
		while (left < right) {
			while (left < right && data[right] > pivot) {
				right--;
			}
			if (left < right) {
				SortUtil.swap(data, left, right);
			}

			while (left < right && data[left] < pivot) {
				left++;
			}
			if (left < right) {
				SortUtil.swap(data, left, right);
			}
		}
		return left;
	}

}

/**
 * 归并排序算法
 */
class MergeSort implements Sort {
	public void sort(int[] data) {
		int[] temp = new int[data.length];
		mergeSort(data, temp, 0, data.length - 1);
	}

	private void mergeSort(int[] data, int[] temp, int left, int right) {
		if (left == right) { return; }
		int mid = (left + right) / 2;
		mergeSort(data, temp, left, mid);
		mergeSort(data, temp, mid + 1, right);
		for (int i = left; i <= right; i++) {
			temp = Arrays.copyOf(data, data.length);
		}
		int i1 = left;
		int i2 = mid + 1;
		for (int cur = left; cur <= right; cur++) {
			if (i1 == mid + 1) {
				data[cur] = temp[i2++];
			} else if (i2 > right) {
				data[cur] = temp[i1++];
			} else if (temp[i1] < temp[i2]) {
				data[cur] = temp[i1++];
			} else {
				data[cur] = temp[i2++];
			}
		}
	}

}

/**
 * 堆排序算法
 */
class HeapSort implements Sort {
	public void sort(int[] data) {
		MaxHeap h = new MaxHeap();
		h.init(data);
		for (int i : data) {
			h.remove();
		}
		System.arraycopy(h.queue, 1, data, 0, data.length);
	}

	private static class MaxHeap {
		void init(int[] data) {
			this.queue = new int[data.length + 1];
			for (int element : data) {
				queue[++size] = element;
				fixUp(size);
			}
		}

		private int size = 0;
		private int[] queue;

		public void remove() {
			SortUtil.swap(queue, 1, size--);
			fixDown(1);
		}

		// fixdown
		private void fixDown(int k) {
			int j;
			while ((j = k << 1) <= size) {
				if (j < size && queue[j] < queue[j + 1]) {
					j++;
				}
				if (queue[k] > queue[j]) { // 不用交换
					break;
				}
				SortUtil.swap(queue, j, k);
				k = j;
			}
		}

		private void fixUp(int k) {
			while (k > 1) {
				int j = k >> 1;
			if (queue[j] > queue[k]) {
				break;
			}
			SortUtil.swap(queue, j, k);
			k = j;
			}
		}

	}

}
```  

```java 
/**
 * 排序算法工具类
 */
class SortUtil {
	public static void swap(int[] data, int i, int j) {
		int temp = data[i];
		data[i] = data[j];
		data[j] = temp;
	}

	public static void print(int[] data) {
		for (int each : data) {
			System.out.print(each + " ");
		}
		System.out.println();
	}
}

```

```java 
/**
 * 冒择入希快归堆：常用排序算法
 * @author wangchaoqun
 */
public class SortTest {

	public static void main(String[] args) {
		int[] origin = { 2, 17, 3, 1, 10, 4, 8, 5, 21, 6, 33, 9, 53 };
		System.out.print("origin:	");
		SortUtil.print(origin);
		// 执行排序算法
		for (Sorts each : Sorts.values()) {
			System.out.print(each.name() + ":	");
			int[] data = Arrays.copyOf(origin, origin.length);
			each.sort(data);
			SortUtil.print(data);
		}
		// api使用经过调优的快速排序
		Arrays.sort(origin);
		System.out.print("jdkApi:	");
		SortUtil.print(origin);
	}

}
```
